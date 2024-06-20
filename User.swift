//
//  User.swift
//  simpl3
//
//  Created by Väinö Kurula on 7.5.2023.
//

// a model to store user information.

import FirebaseFirestoreSwift

struct User:  Codable, Identifiable {
    @DocumentID var id: String?
    let uid, email, profileImageUrl, displayName, playStyle: String
}


