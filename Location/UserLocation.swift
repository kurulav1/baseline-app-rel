//
//  UserLocation.swift
//  simpl3
//
//  Created by Väinö Kurula on 16.5.2023.
//

import FirebaseFirestoreSwift

struct UserLocation: Codable, Identifiable {
    @DocumentID var id: String?
    let uid: String
    let latitude: Double
    let longitude: Double
}
