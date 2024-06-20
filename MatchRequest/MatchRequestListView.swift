//
//  MatchRequestListingView.swift
//  simpl3
//
//  Created by Väinö Kurula on 26.6.2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImage
import SDWebImageSwiftUI



struct MatchRequestListView: View {
    @StateObject private var um = UsersViewModel()
    @State private var matchRequests: [MatchRequest] = []
    
    var body: some View {
        NavigationView {
            VStack {
                navBar
                matchRequestsView
            }
        }
        .onAppear {
            if let currentUser = um.currentUser {
                            fetchMatchRequests()
                        }
        }
    }
    
    private var matchRequestsView: some View {
            List(matchRequests.filter { $0.targetUID == FirebaseManager.shared.auth.currentUser?.uid }) { matchRequest in
                NavigationLink(destination: MatchRequestDetailView(matchRequest: matchRequest)) {
                    if let user = um.users.first(where: { $0.uid == matchRequest.requester }) {
                        VStack(alignment: .leading) {
                            Text("Requester: \(user.displayName)")
                            Text("Date: \(matchRequest.date.dateValue())")
                            //Text("Play Listing ID: \(matchRequest.playListing.documentID)")
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Requester: Unknown User")
                            Text("Date: \(matchRequest.date.dateValue())")
                            //Text("Play Listing ID: \(matchRequest.playListing.documentID)")
                        }
                    }
                }
            }
            .navigationTitle("Match Requests")
            .onAppear {
                fetchMatchRequests()
            }
        }
    
    func fetchMatchRequests() {
        guard let currentUserId = um.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let matchRequestsCollection = db.collection("match_requests")
        
        matchRequestsCollection.whereField("targetUID", isEqualTo: currentUserId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching match requests: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No match requests found.")
                return
            }
            
            do {
                let matchRequests = try documents.compactMap { document in
                    let data = document.data()
                    let id = document.documentID
                    let requester = data["requester"] as? String ?? ""
                    let dateTimestamp = data["date"] as? Timestamp ?? Timestamp()
                    let playListingRef = data["play_listing"] as? DocumentReference
                    let targetUID = data["targetUID"] as? String ?? ""
                    
                    return MatchRequest(id: id, requester: requester, date: dateTimestamp, playListing: playListingRef!, targetUID: targetUID)
                }
                
                DispatchQueue.main.async {
                    self.matchRequests = matchRequests
                }
            } catch {
                print("Error decoding match requests: \(error.localizedDescription)")
            }
        }
    }
    
    private var navBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: um.currentUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(um.currentUser?.email ?? "")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            
            Button(action: {
                um.signOut()
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct MatchRequestDetailView: View {
    let matchRequest: MatchRequest
    @State private var isConfirmationPresented = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Match Request Details")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Requester: \(matchRequest.requester)")
            Text("Date: \(matchRequest.date.dateValue())")
            Text("Play Listing ID: \(matchRequest.playListing.documentID)")
            
            Button(action: {
                isConfirmationPresented = true
            }, label: {
                Text("Accept")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            })
            .padding()
            .alert(isPresented: $isConfirmationPresented) {
                Alert(
                    title: Text("Confirmation"),
                    message: Text("Are you sure you want to accept this match request?"),
                    primaryButton: .default(Text("Accept"), action: {
                        acceptMatchRequest(matchRequest)
                    }),
                    secondaryButton: .cancel()
                )
            }
            
            Spacer()
        }
        .padding()
    }
    
    func acceptMatchRequest(_ matchRequest: MatchRequest) {
        let db = Firestore.firestore()

        // Get match request reference
        let matchRequestsCollection = db.collection("match_requests")

        // Delete the accepted match request from the collection
        matchRequestsCollection.document(matchRequest.id!).delete { error in
            if let error = error {
                print("Error deleting match request: \(error.localizedDescription)")
            } else {
                print("Match request deleted successfully.")
            }
        }

        // Fetch the logged-in user UID
        guard let currentUserUID = FirebaseManager.shared.auth.currentUser?.uid else {
            print("No user logged in")
            return
        }

        // Create DocumentReference from the path stored in matchRequest
        let playListingRef = db.document(matchRequest.playListing.path)

        // Fetch the Play Listing details like location and date
        playListingRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching play listing: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data(),
                  let description = data["description"] as? String,
                  let listingDateTimestamp = data["listingDate"] as? Timestamp else {
                print("Could not fetch play listing details")
                return
            }
            
            let date = listingDateTimestamp.dateValue()

            // Create a new ScheduledMatch object
            let scheduledMatch = ScheduledMatch(
                player1_uid: matchRequest.requester,
                player2_uid: currentUserUID,
                date: date,
                location: description,
                additionalNotes: "No additional notes",
                duration: "Duration"
            )

            do {
                // Save the scheduled match to Firestore
                _ = try db.collection("scheduled_matches").addDocument(from: scheduledMatch)
                print("Scheduled match created successfully.")
            } catch {
                print("Error creating scheduled match: \(error.localizedDescription)")
            }
        }
    }
}
