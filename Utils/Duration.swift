//
//  Duration.swift
//  simpl3
//
//  Created by Väinö Kurula on 21.6.2023.
//


import SwiftUI

struct Duration: Codable {
    let minutes: Int
    
    init(minutes: Int) {
        self.minutes = minutes
    }
    
    var hours: Int {
        return minutes / 60
    }
    
    var days: Int {
        return hours / 24
    }
    
    var formattedString: String {
        let hoursRemainder = minutes % 60
        return "\(days) days, \(hours) hours, \(hoursRemainder) minutes"
    }
}
