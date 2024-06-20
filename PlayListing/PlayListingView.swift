//
//  PlayListingView.swift
//  simpl3
//
//  Created by Väinö Kurula on 23.5.2023.
//

import SwiftUI
import FirebaseFirestoreSwift
import FirebaseCore
import FirebaseFirestore
import SDWebImage
import SDWebImageSwiftUI

class PlayListingViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var approximateLocation = ""
    @Published var listingDate = ""
    @Published var matchRequestCreated = false
    @Published var author: User? // Add author property
    
    var listing: PlayListing?
    
    init(listing: PlayListing?) {
        self.listing = listing
        if let date = listing?.listingDate?.dateValue() {
            listingDate = formatDate(date: date)
        }
        fetchAuthorData() // Fetch author data when initializing
    }

    // Add this function to format the date
    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func makeMatchRequest() {
        guard let playListingId = listing?.id,
              let requester = FirebaseManager.shared.auth.currentUser?.uid else {
            errorMessage = "Failed to create match request. Invalid data."
            return
        }
        
        let db = Firestore.firestore()
        let matchRequestsCollection = db.collection("match_requests")
        
        let newMatchRequestData: [String: Any] = [
            "requester": requester,
            "date": FieldValue.serverTimestamp(),
            "play_listing": db.document("play_listing/\(playListingId)"),
            "targetUID": listing?.authorRef.documentID // Use authorRef's documentID as targetUID
        ]
        
        matchRequestsCollection.addDocument(data: newMatchRequestData) { error in
            if let error = error {
                self.errorMessage = "Failed to create match request: \(error.localizedDescription)"
            } else {
                self.matchRequestCreated = true
            }
        }
    }
    
    func fetchAuthorData() {
        guard let authorRef = listing?.authorRef else {
            print("Author reference not available")
            return
        }
        
        authorRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching author data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Author data not found")
                return
            }
            
            if let author = try? document.data(as: User.self) {
                self.author = author
            }
        }
    }
}

struct PlayListingView: View {
    @ObservedObject var plm: PlayListingViewModel
    @State private var isMatchRequestAlertPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let author = plm.author {
                        VStack {
                            if let profileImageUrl = URL(string: author.profileImageUrl) {
                                // Display profile picture here with SDWebImage
                                WebImage(url: profileImageUrl)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.label), lineWidth: 1)
                                    )
                                    .shadow(radius: 5)
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.label), lineWidth: 1)
                                    )
                                    .foregroundColor(.gray) // Placeholder icon color
                                    .shadow(radius: 5)
                            }
                            
                            Text(author.displayName)
                                .font(.headline)
                                .padding(.top, 8)
                        }
                    }
                    
                    if let city = plm.listing?.city {
                                            Text("City: \(city)")
                                        }
                    
                    Text("Description:")
                    TextField("", text: .constant((plm.listing?.description)!))
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Date: \(plm.listingDate)")
                    
                    Button(action: {
                        plm.makeMatchRequest()
                        isMatchRequestAlertPresented = true
                    }) {
                        Text("Request Match")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .alert(isPresented: $isMatchRequestAlertPresented) {
                        Alert(
                            title: Text("Match Request"),
                            message: Text(plm.matchRequestCreated ? "Match request created successfully!" : "Failed to create match request."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    
                    NavigationLink(destination: ForeignProfileView(vm: ForeignProfileViewModel(user: plm.author))) {
                        Text("View Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Play Listing")
        }
    }
}
