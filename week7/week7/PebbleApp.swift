import SwiftUI

enum AppTab: Hashable {
    case moment
    case chat
    case camera
    case memories
    case profile
}

@main
struct PebbleApp: App {
    @StateObject private var store = MomentStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootTabView: View {
    @State private var tab: AppTab = .moment

    private let accentColor = Color(
        red: 0.83,
        green: 1.0,
        blue: 0.24
    )

    private let backgroundColor = Color(
        red: 0.055,
        green: 0.055,
        blue: 0.06
    )

    var body: some View {
        TabView(selection: $tab) {

            // Moment
            MomentView(selectedTab: $tab)
                .tabItem {
                    Label(
                        "Moment",
                        systemImage: "square.stack.3d.up"
                    )
                }
                .tag(AppTab.moment)

            // Chat
            PlaceholderView(
                title: "Chat",
                symbol: "bubble.left.and.bubble.right"
            )
            .tabItem {
                Label(
                    "Chat",
                    systemImage: "bubble.left.and.bubble.right"
                )
            }
            .tag(AppTab.chat)

            // Camera
            CameraView(selectedTab: $tab)
                .tabItem {
                    Label(
                        "Camera",
                        systemImage: "viewfinder"
                    )
                }
                .tag(AppTab.camera)

            // Memories
            PlaceholderView(
                title: "Memories",
                symbol: "rectangle.stack"
            )
            .tabItem {
                Label(
                    "Memories",
                    systemImage: "rectangle.stack"
                )
            }
            .tag(AppTab.memories)

            // Profile
            PlaceholderView(
                title: "Profile",
                symbol: "person.crop.circle"
            )
            .tabItem {
                Label(
                    "Profile",
                    systemImage: "person.crop.circle"
                )
            }
            .tag(AppTab.profile)
        }
        .tint(accentColor)
        .toolbarBackground(
            backgroundColor,
            for: .tabBar
        )
        .toolbarBackground(
            .visible,
            for: .tabBar
        )
    }
}

struct PlaceholderView: View {
    let title: String
    let symbol: String

    private let accentColor = Color(
        red: 0.83,
        green: 1.0,
        blue: 0.24
    )

    private let backgroundColor = Color(
        red: 0.055,
        green: 0.055,
        blue: 0.06
    )

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(
                        .system(
                            size: 42,
                            weight: .light
                        )
                    )
                    .foregroundStyle(accentColor)

                Text(title.uppercased())
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(.white)

                Text("COMING SOON")
                    .font(
                        .system(
                            size: 10,
                            weight: .medium
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(.gray)
            }
        }
    }
}
