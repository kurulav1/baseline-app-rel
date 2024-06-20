//
//  Message.swift
//  simpl3
//
//  Created by Väinö Kurula on 11.5.2023.
//

import Foundation
import FirebaseFirestoreSwift

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
