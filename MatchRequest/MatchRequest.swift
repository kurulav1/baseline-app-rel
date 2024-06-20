//
//  MatchRequest.swift
//  simpl3
//
//  Created by Väinö Kurula on 26.6.2023.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseCore
import FirebaseFirestore 


struct MatchRequest: Codable, Identifiable {
    @DocumentID var id: String?
    let requester: String
    let date: Timestamp
    let playListing: DocumentReference
    let targetUID: String
}
