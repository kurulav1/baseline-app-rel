//
//  ScheduledMatchesView.swift
//  simpl3
//
//  Created by Väinö Kurula on 21.6.2023.
//

import Foundation
import SwiftUI
import Firebase
import SDWebImageSwiftUI
import FirebaseFirestoreSwift

struct ScheduledMatchesView: View {
    @StateObject private var viewModel = ScheduledMatchesViewModel()
    @State private var selectedMatch: ScheduledMatch?
    
    var body: some View {
        NavigationView {
            List(viewModel.matches) { match in
                Button(action: {
                    selectedMatch = match
                }) {
                    ScheduledMatchRow(match: match)
                }
            }
            .navigationTitle("Scheduled Matches")
            .sheet(item: $selectedMatch) { match in
                ScheduledMatchDetailView(match: match)
            }
            .onAppear {
                viewModel.fetchMatches()
            }
        }
    }
}


struct ScheduledMatchRow: View {
    let match: ScheduledMatch
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Date: \(formattedDate)")
                .font(.headline)
            
            if let location = match.location {
                Text("Location: \(location)")
            }
            
            if let duration = match.duration {
                Text("Duration: \(duration)")
            }
        }
        .padding()
    }
    
    private var formattedDate: String {
        guard let date = match.date else {
            return "Unknown"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
}

class ScheduledMatchesViewModel: ObservableObject {
    @Published var matches: [ScheduledMatch] = []

    private var firestoreListener: ListenerRegistration?

    func fetchMatches() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        firestoreListener = Firestore.firestore()
            .collection("scheduled_matches")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Failed to fetch scheduled matches: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }

                self.matches = documents.compactMap { queryDocumentSnapshot in
                    do {
                        let match = try queryDocumentSnapshot.data(as: ScheduledMatch.self)
                        if match.player1_uid == uid || match.player2_uid == uid {
                            return match
                        } else {
                            return nil
                        }
                    } catch {
                        print("Failed to decode scheduled match: \(error)")
                        return nil
                    }
                }
            }
    }
}
