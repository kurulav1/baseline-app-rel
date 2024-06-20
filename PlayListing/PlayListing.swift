//
//  PlayListing.swift
//  simpl3
//
//  Created by Väinö Kurula on 22.5.2023.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseCore
import FirebaseFirestore


struct PlayListing: Codable, Identifiable {
    @DocumentID var id: String?
    let authorRef: DocumentReference
    let authorUid: String?
    let listingDate: Timestamp?
    let description: String?
    let city: String? // New field for city
}
