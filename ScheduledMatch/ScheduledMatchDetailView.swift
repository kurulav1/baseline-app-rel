//
//  ScheduledMatchDetailView.swift
//  simpl3
//
//  Created by Väinö Kurula on 21.6.2023.
//

import Foundation
import SwiftUI

struct ScheduledMatchDetailView: View {
    let match: ScheduledMatch
    @StateObject var um = UsersViewModel() // Initialize the UserViewModel
    
    var body: some View {
        VStack {
            Spacer()

            Text("Match Details")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            Group {
                HStack {
                    Text("Player 1:")
                        .font(.headline)
                    Spacer()
                    Text(getPlayerName(match.player1_uid))
                        .font(.body)
                }
                .padding(.vertical)

                HStack {
                    Text("Player 2:")
                        .font(.headline)
                    Spacer()
                    Text(getPlayerName(match.player2_uid))
                        .font(.body)
                }
                .padding(.vertical)

                HStack {
                    Text("Date:")
                        .font(.headline)
                    Spacer()
                    Text(formattedDate)
                        .font(.body)
                }
                .padding(.vertical)
            }
            
            if let location = match.location {
                HStack {
                    Text("Location:")
                        .font(.headline)
                    Spacer()
                    Text(location)
                        .font(.body)
                }
                .padding(.vertical)
            }
            
            if let duration = match.duration {
                HStack {
                    Text("Duration:")
                        .font(.headline)
                    Spacer()
                    Text(duration)
                        .font(.body)
                }
                .padding(.vertical)
            }
            
            if let notes = match.additionalNotes {
                VStack(alignment: .leading) {
                    Text("Additional Notes:")
                        .font(.headline)
                        .padding(.vertical)
                    Text(notes)
                        .font(.body)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            um.fetchAllUsers()
        }
    }
    
    private func getPlayerName(_ uid: String?) -> String {
        // Search for the user in the fetched users
        guard let uid = uid else { return "Unknown" }
        if let user = um.users.first(where: { $0.uid == uid }) {
            return user.displayName
        }
        return "Unknown"
    }
    
    private var formattedDate: String {
        guard let date = match.date else {
            return "Unknown"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
}
