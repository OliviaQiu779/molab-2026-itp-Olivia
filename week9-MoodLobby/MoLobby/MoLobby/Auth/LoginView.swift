//
//  LoginView.swift

import SwiftUI

// ?? Why not centered vertically with Spacers

struct LoginView: View {
    
    @Environment(LobbyModel.self) var lobbyModel

    @Environment(AppModel.self) var app
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            VStack {
                Text("MoLobbyApp")
                    .font(.system(size: 50, weight: .bold))
                // Spacer()

                Text("""
Welcome to MoLobby version \(app.verNum)
""")
                // Button move from bottom to avoid getting overlaid with links
                // and rendered inaccessible
                
                GoogleSignInButton()
                    .padding()
                    .onTapGesture {
                        lobbyModel.signIn()
                    }

                Button(action: lobbyModel.signInAnonymously) {
                    Text("Sign In Anonymously")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(.systemIndigo))
                        .cornerRadius(12)
                        .padding(5)
                }

                Text("""
Hello!
""")
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(2)
                
//                Link("Video overview youtube.com",
//                     destination:
//                        URL(string: "https://jht1493.net/MoGallery/VideoOverView")! )
//                .padding(14)
//                Link("MoGallery github.com",
//                     destination:
//                        URL(string: "https://github.com/mobilelabclass-itp/98-MoGallery")! )
//                .padding(14)
                
            }
        }
        .onAppear {
            print("LoginView onAppear currentUser", lobbyModel.currentUser?.email ?? "-none-")
        }
        .onDisappear {
            print("LoginView onDisappear")
            app.locationManager.requestUse();
        }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
