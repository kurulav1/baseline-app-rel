//
//  ForeignProfileView.swift
//  simpl3
//
//  Created by Väinö Kurula on 14.5.2023.
//

import SwiftUI
import FirebaseFirestoreSwift
import FirebaseCore
import FirebaseFirestore


class ForeignProfileViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var isCurrentlyLoggedOut = false
    @Published var playStyle = ""
    @Published var displayName = ""
    
    var user: User?
    
    init(user: User?) {
        self.user = user
        fetchUserData()
    }
    
    func fetchUserData() {
        guard let uid = user?.uid else {
            print("User is not logged in")
            return
        }
        
        let db = FirebaseManager.shared.firestore
        let docRef = db.collection("users").whereField("uid", isEqualTo: uid)
        
        docRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("User data not found")
                return
            }
            
            for document in snapshot.documents {
                let data = document.data()
                self.playStyle = data["play_style"] as? String ?? ""
                self.displayName = data["display_name"] as? String ?? ""
            }
        }
    }
}

struct ForeignProfileView: View {
    @ObservedObject var vm: ForeignProfileViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("User ID:")
                        .font(.headline)
                    TextField("", text: .constant(vm.user?.uid ?? ""))
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Email:")
                        .font(.headline)
                    TextField("", text: .constant(vm.user?.email ?? ""))
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Playstyle:")
                    TextField("", text: .constant(vm.playStyle))
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Display Name:")
                    TextField("", text: .constant(vm.displayName))
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}
