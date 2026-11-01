//Modify LobbyView.swift in my MoLobby project to turn the existing user lobby into a simple “Mood Lobby.” Add four mood buttons: 🙂 Happy, 😴 Sleepy, 😵 Busy, and 😌 Relaxed. When a user selects a mood, save it in their existing caption field using LobbyModel.updateUser(user:). Highlight the selected mood and show each user’s name and latest mood in the shared list. Give anonymous users a short guest label so they can be distinguished. Keep the Sign Out button, but remove the profile-editing links, anonymous-user deletion button, and settings toggle. Reuse the existing Firebase synchronization without modifying LobbyModel.swift or adding new files.

import SwiftUI

struct LobbyView: View {
    @Environment(LobbyModel.self) var lobbyModel

    private let moods = ["🙂 Happy", "😴 Sleepy", "😵 Busy", "😌 Relaxed"]

    var body: some View {
        NavigationStack {
            List {
                Section("How are you feeling?") {
                    if let currentUser = lobbyModel.currentUser {
                        Text("Hi, \(displayName(currentUser))!")
                            .font(.headline)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(moods, id: \.self) { mood in
                                Button {
                                    currentUser.caption = mood
                                    lobbyModel.updateUser(user: currentUser)
                                } label: {
                                    Text(mood)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .background(
                                            currentUser.caption == mood
                                                ? Color.indigo.opacity(0.2)
                                                : Color.gray.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    currentUser.caption == mood
                                                        ? Color.indigo : Color.clear,
                                                    lineWidth: 2
                                                )
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(
                                    currentUser.caption == mood ? .isSelected : []
                                )
                            }
                        }
                        .padding(.vertical, 8)

                        Text("Your mood: \(moodText(currentUser))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView("Loading your profile…")
                    }
                }

                Section {
                    if lobbyModel.users.isEmpty {
                        Text("No moods shared yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(lobbyModel.users) { user in
                        HStack {
                            Text(displayName(user))
                                .font(.headline)
                            if user.id == lobbyModel.currentUser?.id {
                                Text("(you)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(moodText(user))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                } header: {
                    Text("Everyone’s mood · \(lobbyModel.users.count) members")
                } footer: {
                    Text("Everyone’s last shared mood stays here, even when they leave.")
                }
            }
            .navigationTitle("Mood Lobby")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out", action: lobbyModel.signOut)
                }
            }
        }
        .tint(.indigo)
    }

    private func displayName(_ user: UserModel) -> String {
        if user.name.isEmpty || user.name == "Anonymous" {
            return "Guest \(user.id.suffix(4))"
        }
        return user.name
    }

    private func moodText(_ user: UserModel) -> String {
        moods.contains(user.caption) ? user.caption : "Not shared yet"
    }
}

// Retained from the template in case another view uses it.
struct LocationRow: View {
    var user: UserModel

    var body: some View {
        if let locationDescription = user.locationDescription {
            Text(locationDescription)
        }
    }
}
