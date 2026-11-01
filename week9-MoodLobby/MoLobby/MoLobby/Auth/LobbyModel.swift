// LobbyModel
//

import Firebase
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore
import Observation
//import MapKit

//struct MapRegionModel {
//    var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.334_900,
//                                       longitude: -122.009_020),
//        latitudinalMeters: 750,
//        longitudinalMeters: 750
//    )
//    var locIndex = 0
//    var regionLabel = ""
//    var locs: [Location] = []
//}

@Observable class LobbyModel {
    enum SignInState {
        case signedIn
        case signedOut
        case signedInFresh
    }
    var state: SignInState = .signedOut
    var users: [UserModel] = []
    var albumName = ""
    
//    var mapRegion = MapRegionModel()
    
    // Observed so MainView switches between LoginView and LobbyView
    var currentUser: UserModel?

    static let main = LobbyModel()
    static let anonymousName = "Anonymous"
    @ObservationIgnored lazy var app = AppModel.main
    
    var uid: String! {
        currentUser?.id
    }

    // mo-lobby
    @ObservationIgnored var lobbyRef: CollectionReference? // users collection
    @ObservationIgnored var lobbyListener: ListenerRegistration?

    func refresh() {
        observeStop()
        lobbyRef = FirestorePaths.lobbyUsers(
            prefix: app.settings.storePrefix,
            lobbyKey: app.settings.storeLobbyKey)
        observeStart()
        albumName = app.settings.photoAlbum
    }
    
    func user(uid: String) -> UserModel? {
        return users.first{ $0.id == uid }
    }

    // Anonymous entries, except the current user who is still signed in
    var removableAnonymousUsers: [UserModel] {
        users.filter { $0.name == LobbyModel.anonymousName && $0.id != currentUser?.id }
    }

    func removeAnonymousUsers() {
        guard let lobbyRef else { return }
        for user in removableAnonymousUsers {
            lobbyRef.document(user.id).delete { error in
                if let error = error {
                    xprint("removeAnonymousUsers delete error", user.id, error.localizedDescription)
                }
            }
        }
    }

    func signIn() {
        xprint("LobbyModel signIn", state)
        // Firebase persists the anonymous user, resume without Google sign in
        if Auth.auth().currentUser?.isAnonymous == true {
            setSignedIn()
            return
        }
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            xprint("LobbyModel signIn restorePreviousSignIn", state)
            
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
                if let error = error {
                    // Stale refresh token in keychain (eg. invalid_grant on Mac)
                    // clear it and fall back to interactive sign in
                    xprint("LobbyModel restorePreviousSignIn error", error.localizedDescription)
                    GIDSignIn.sharedInstance.signOut()
                    signInInteractive()
                    return
                }
                authenticateUser(for: user, with: error)
            }
        } else {
            signInInteractive()
        }
    }

    func signInInteractive() {
        xprint("LobbyModel signIn GIDConfiguration", state)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] signInResult, error in
            self.authenticateUser(for: signInResult?.user, with: error)
        }
    }
    
    func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            xprint("authenticateUser error 1", error.localizedDescription)
            return
        }
        guard let idToken = user!.idToken?.tokenString else { return  };
        let accessToken = user!.accessToken.tokenString;
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        Auth.auth().signIn(with: credential) { [unowned self] (_, error) in
            if let error = error {
                xprint("authenticateUser error 2", error.localizedDescription)
            } else {
                setSignedIn()
            }
        }
    }
    
    func signInAnonymously() {
        // anonymous authentication.
        // setSignedIn must wait for the callback, updateCurrentUser needs the uid
        Auth.auth().signInAnonymously { [unowned self] (_, error) in
            if let error = error {
                xprint("signInAnonymously error", error.localizedDescription)
            } else {
                setSignedIn()
            }
        }
    }

    func setSignedIn() {
        xprint("setSignedIn state", state)
        if state != .signedIn {
            state = .signedIn
            xprint("setSignedIn set signedIn", state)
            updateCurrentUser()
            // All Firebase references need to be refreshed when moving from logged out state
            // galleryModel countMine depends on current user uid
            app.lobbyModel.refresh()
//            app.galleryModel.refresh()
            // app.metaModel.refresh()
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
            state = .signedOut
            currentUser = nil
        } catch {
            xprint("signOut error", error.localizedDescription)
        }
    }
        
    // First time user is inited in mo-users
    // update db user property dateIn with current time in seconds
    //
    func updateCurrentUser() {
        guard let lobbyRef else { return }
        
        let id = Auth.auth().currentUser?.uid ?? ""
        let guser = GIDSignIn.sharedInstance.currentUser;
        let isAnonymous = Auth.auth().currentUser?.isAnonymous == true
        let name = isAnonymous ? LobbyModel.anonymousName : guser?.profile?.name ?? ""
        let email = guser?.profile?.email ?? ""
        let profileImg = guser?.profile?.imageURL(withDimension: 80)?.description ?? ""
        let dateIn = Date().timeIntervalSinceReferenceDate

        var values:[String : Any] = [:];
        values["name"] = name
        values["email"] = email
        values["profileImg"] = profileImg
        values["dateIn"] = dateIn;
        values["uploadCount"] = 0

        xprint("updateCurrentUser id", id)
        // print("value", values);

        // !!@ Fails to get single value as documented
//        let childRef = lobbyRef.child("/\(id)/uploadCount")
//        let childRef = lobbyRef.child(id).child("uploadCount")
//        childRef.getData() { error, snapshot in
//            guard error == nil else {
//                xprint(" getData error",error!.localizedDescription)
//                return;
//            }
//            xprint("getData snapshot", snapshot ?? "-nil-");
//            if let num = snapshot?.value as? Int {
//                xprint("getData num", num);
//            }
//        }
        // Current user location is update on each login check
        if let loc = app.locationManager.lastLocation {
            values["lat"] = loc.coordinate.latitude;
            values["lon"] = loc.coordinate.longitude
        }

        let userDoc = lobbyRef.document(id)
        userDoc.getDocument { snapshot, error in
            if let error = error {
                xprint("updateCurrentUser getDocument error", error.localizedDescription)
            }
            var updateValues = values
            var localValues = values
            if let data = snapshot?.data() {
                let uploadCount = data["uploadCount"] as? Int ?? 0
                updateValues["uploadCount"] = uploadCount
                localValues["uploadCount"] = uploadCount
                let activeCount = (data["activeCount"] as? Int ?? 0) + 1
                localValues["activeCount"] = activeCount
            } else {
                localValues["activeCount"] = 1
            }
            updateValues["activeCount"] = FieldValue.increment(Int64(1))
            // Update db user properies
            userDoc.setData(updateValues, merge: true) { error in
                if let error = error {
                    xprint("postUser setData error: \(error).")
                }
            }
            self.currentUser = UserModel(id: id, dict: localValues)
        }
    }
    
    func updateUser(user: UserModel) {
        xprint("updateUser updateUser", updateUser)
        guard let lobbyRef else { return }
        
        var values:[String : Any] = [:];
        values["caption"] = user.caption
        values["stats"] = user.stats
        lobbyRef.document(user.id).setData(values, merge: true) { error in
            if let error = error {
                xprint("updateUser setData error: \(error).")
            }
        }
    }
    
    func observeStart() {
        guard let lobbyRef else { return }
        xprint("observeUsersStart lobbyListener", lobbyListener as Any)
        if lobbyListener != nil {
            return;
        }
        lobbyListener = lobbyRef.addSnapshotListener { snapshot, error in
            if let error = error {
                xprint("LobbyModel snapshot error", error.localizedDescription)
                return
            }
            guard let snapshot else {
                xprint("LobbyModel snapshot nil")
                self.users = []
                return
            }
            self.receiveSnapShot(snapshot)
        }
    }

    func receiveSnapShot(_ snapshot: QuerySnapshot) {
        let docs = snapshot.documents
        guard !docs.isEmpty else {
            xprint("LobbyModel users EMPTY")
            self.users = []
            return
        }
        let items = docs.compactMap { UserModel(id: $0.documentID, dict: $0.data()) }
        let sortedItems = items.sorted(by: { $0.dateIn > $1.dateIn })
        users = sortedItems;
        // Update current user check
        if let user = currentUser,
           let nuser = sortedItems.first(where: { $0.id == user.id }) {
            xprint("LobbyModel currentUser nuser.id", nuser.id)
            currentUser = nuser
        }
        xprint("LobbyModel users.count", users.count)
//        locsForUsers(firstLoc: nil)
    }
    
    func observeStop() {
        xprint("observeUsersStop lobbyListener", lobbyListener as Any)
        if let listener = lobbyListener {
            listener.remove()
            lobbyListener = nil;
        }
    }
    
//    func locsForUsers(firstLoc: Location?) {
//        xprint("locsForUsers firstLoc", firstLoc ?? "-nil-")
//        var locs = [Location]()
//        if let firstLoc {
//            locs.append(firstLoc)
//        }
//        users.forEach { user in
//            if let loc = user.loc {
//                locs.append( loc )
//            }
//        }
//        if let last = app.locationManager.lastLocation {
//            let center = last.coordinate
//            locs.append(Location(id: "current", latitude: center.latitude, longitude: center.longitude, label: "current") )
//        }
//        self.mapRegion.locs = locs
//    }
}

//
// Firebase database, storage and auth docs
//  https://firebase.google.com/docs/database/ios/read-and-write?hl=en&authuser=0
//  https://firebase.google.com/docs/storage/ios/start?hl=en&authuser=0
//-- sample code
//  https://github.com/firebase/quickstart-ios/blob/master/database/README.md
//  https://github.com/firebase/quickstart-ios/blob/master/storage/README.md
//
// Google Sign-In & Firebase Authentication Using SwiftUI
//  https://github.com/rudrankriyam/Ellifit
//  https://blog.codemagic.io/google-sign-in-firebase-authentication-using-swift/
// requires google signin verion 6.x

// https://developer.apple.com/documentation/photokit/selecting_photos_and_videos_in_ios
// Selecting Photos and Videos in iOS
// Load Asset Metadata
