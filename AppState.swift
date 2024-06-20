//
//  AppState.swift
//  simpl3
//
//  Created by Väinö Kurula on 1.7.2023.
//

import Foundation
class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var user: User?
    
    func reset() {
        isLoggedIn = false
        user = nil
    }
}
