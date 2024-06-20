//
//  ScheduledMatch.swift
//  simpl3
//
//  Created by Väinö Kurula on 21.6.2023.
//

import Foundation
import FirebaseFirestoreSwift

struct ScheduledMatch: Codable, Identifiable {
    @DocumentID var id: String?
    let player1_uid: String?
    let player2_uid: String?
    let date: Date?
    let location: String?
    let additionalNotes: String?
    let duration: String?
}

