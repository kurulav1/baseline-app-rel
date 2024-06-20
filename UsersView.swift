//
//  UsersView.swift
//  simpl3
//
//  Created by Väinö Kurula on 7.5.2023.
//

// A view to show a list of users.

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImageSwiftUI

class UsersViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var errorMessage = ""
    @Published var currentUser: User?
    @Published var isCurrentlyLoggedOut = true
    
    init() {
        // Check the auth state
        FirebaseManager.shared.auth.addStateDidChangeListener { [weak self] (auth, user) in
            if let firebaseUser = user {
                self?.fetchUser(for: firebaseUser.uid) { user in
                    self?.currentUser = user
                    if let user = user {
                        self?.fetchAllUsers()
                    } else {
                        self?.users.removeAll()
                    }
                }
            } else {
                self?.currentUser = nil
                self?.users.removeAll()
            }
        }
    }

    func fetchUser(for uid: String, completion: @escaping (User?) -> Void) {
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { documentSnapshot, error in
            if let error = error {
                print("Error getting user: \(error)")
                completion(nil)
            } else {
                let user = try? documentSnapshot?.data(as: User.self)
                completion(user)
            }
        }
    }
    
    func fetchAllUsers() {
        // Clear users before fetching
        users.removeAll()
        
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch users: \(error)"
                    print("Failed to fetch users: \(error)")
                    return
                }
                
                documentsSnapshot?.documents.forEach { snapshot in
                    guard let user = try? snapshot.data(as: User.self) else {
                        print("Failed to decode user data for document: \(snapshot.documentID)")
                        return
                    }
                    
                    if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                        self.users.append(user)
                    }
                }
            }
    }
    
    func clearUsers() {
        users.removeAll()
    }
    
    func signOut() {
        do {
            try FirebaseManager.shared.auth.signOut()
            clearUsers()
            isCurrentlyLoggedOut.toggle()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

struct UsersView: View { 
    @StateObject private var appState = AppState()
    
    @ObservedObject var um = UsersViewModel()
    @State private var shouldShowLogOutOptions = false
    
    var body: some View {
        NavigationView {
            VStack {
                navBar
                usersView
            }
        }
        .fullScreenCover(isPresented: $um.isCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(
                didCompleteLoginProcess: {
                    self.um.isCurrentlyLoggedOut = false
                    self.um.fetchAllUsers() // Fetch users after login
                }
            )
        }
        .onAppear {
            um.fetchAllUsers() // Fetch users data every time the view appears
        }
    }
    
    private var usersView: some View {
            ScrollView {
                if !um.errorMessage.isEmpty {
                    Text(um.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ForEach(um.users, id: \.uid) { user in
                    let vm = LogViewModel(user: user)
                    NavigationLink(destination: MessagesView(vm: vm)) {
                        HStack(spacing: 16) {
                            if let url = URL(string: user.profileImageUrl) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.label), lineWidth: 1)
                                    )
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.label), lineWidth: 1)
                                    )
                                    .foregroundColor(.gray) // Placeholder icon color
                            }
                            
                            Text(user.displayName)
                                .foregroundColor(Color(.label))
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button style
                    
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
    
    private var navBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: um.currentUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(um.currentUser?.displayName ?? "")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            
            Button(action: {
                shouldShowLogOutOptions.toggle()
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            .padding()
            .actionSheet(isPresented: $shouldShowLogOutOptions) {
                ActionSheet(
                    title: Text("Settings"),
                    message: Text("What do you want to do?"),
                    buttons: [
                        .destructive(Text("Sign Out"), action: {
                            um.signOut() // Sign out and clear users
                        }),
                        .cancel()
                    ]
                )
            }
        }
        .padding(.horizontal)
    }
}
