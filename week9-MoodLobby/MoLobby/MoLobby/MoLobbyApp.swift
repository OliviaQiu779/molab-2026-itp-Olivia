/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI
import Firebase

func xprint(_ args:Any...) {
  print( args )
  // debugPrint( args )
}

// Init firebase and signIn on view appear

@main
struct MoLobbyApp: App {
    
// !!@ not done in
// quickstart-ios/firestore/FirestoreSwiftUIExample/FirestoreSwiftUIExampleApp.swift
// register app delegate for Firebase setup
// @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var app = AppModel.main;

    init() {
        UINavigationBar.applyCustomAppearance()
        FirebaseApp.configure()
        app.initRefresh()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginCheckView()
                .environment(AppModel.main)
                .environment(LobbyModel.main)
                .onAppear {
                    xprint("MoLobbyApp onAppear")
                    // For UIApplicationDelegateAdaptor must refreshModels here
                    // app.refreshModels()
                    app.lobbyModel.signIn()
                }
                .onDisappear {
                    xprint("MoLobbyApp onDisappear")
                }
        }
    }
}

fileprivate extension UINavigationBar {
    
    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// !!@ Google sample code Database / Storage does not use UIApplicationDelegate
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        FirebaseApp.configure()
//        return true
//    }
//}

// Following latest sample code setup gives this warning
// 2023-01-13 12:40:38.561186-0500 MoGallery[17202:2835966] 9.6.0 - [GoogleUtilities/AppDelegateSwizzler][I-SWZ001014]
//  App Delegate does not conform to UIApplicationDelegate protocol.
//
// https://peterfriese.dev/posts/swiftui-new-app-lifecycle-firebase/
// recommends: Start using the SwiftUI App Life Cycle
