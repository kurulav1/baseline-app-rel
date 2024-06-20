//
//  AppViewModel.swift
//  simpl3
//
//  Created by Väinö Kurula on 4.7.2023.
//

import Foundation

class AppViewModel: ObservableObject {
    @Published var isUserAuthenticated: Bool = false

    init() {
        FirebaseManager.shared.auth.addStateDidChangeListener { [weak self] (auth, user) in
            self?.isUserAuthenticated = user != nil
        }
    }

    func signOut() {
        do {
            try FirebaseManager.shared.auth.signOut()
           // GIDSignIn.sharedInstance.signOut() // Google sign out
            isUserAuthenticated = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
