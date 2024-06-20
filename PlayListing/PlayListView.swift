//
//  PlayListView.swift
//  simpl3
//
//  Created by Väinö Kurula on 22.5.2023.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImageSwiftUI
import FirebaseAuth

class PlayListViewModel: ObservableObject {
    
    @Published var combinedListings = [CombinedListing]()
    @Published var errorMessage = ""
    
    init(user: User) {
        fetchCombinedListings(user: user)
    }
    
    func refresh(user: User) {
            fetchCombinedListings(user: user)
        }
    
    private func fetchCombinedListings(user: User) {
        FirebaseManager.shared.firestore.collection("play_listing")
            .getDocuments { [weak self] documentsSnapshot, error in
                if let error = error {
                    self?.errorMessage = "Failed to fetch play listings: \(error)"
                    print("Failed to fetch play listings: \(error)")
                    return
                }
                
                var combinedListings = [CombinedListing]()
                
                documentsSnapshot?.documents.forEach { snapshot in
                    guard let listing = try? snapshot.data(as: PlayListing.self) else {
                        print("Failed to decode listing data for: \(snapshot.documentID)")
                        return
                    }
                    
                    let combinedListing = CombinedListing(playListing: listing)
                    combinedListings.append(combinedListing)
                }
                
                self?.combinedListings = combinedListings
                self?.matchUsersToCombinedListings(user: user)
            }
    }
    
    private func matchUsersToCombinedListings(user: User) {
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments { [weak self] documentsSnapshot, error in
                if let error = error {
                    self?.errorMessage = "Failed to fetch users: \(error)"
                    print("Failed to fetch users: \(error)")
                    return
                }

                documentsSnapshot?.documents.forEach { snapshot in
                    guard let user = try? snapshot.data(as: User.self) else {
                        print("Failed to decode user data for document: \(snapshot.documentID)")
                        return
                    }
                    
                    self?.combinedListings.indices.forEach { index in
                        if self?.combinedListings[index].playListing.authorRef.documentID == user.uid {
                            self?.combinedListings[index].user = user
                        }
                    }
                }
            }
    }
}

struct CombinedListing: Identifiable {
    let id = UUID()
    let playListing: PlayListing
    var user: User?
}

struct PlayListView: View {
    @ObservedObject var plvm: PlayListViewModel
            
        init() {
            if let currentUser = FirebaseManager.shared.currentUser {
                plvm = PlayListViewModel(user: currentUser)
            } else {
                let fallbackUser = User(id: "", uid:"0", email: "", profileImageUrl:"google.com", displayName: "",playStyle:"google.com")
                plvm = PlayListViewModel(user: fallbackUser)
            }
        }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if !plvm.combinedListings.isEmpty {
                    listingsView
                } else if !plvm.errorMessage.isEmpty {
                    VStack {
                        Text(plvm.errorMessage)
                            .foregroundColor(.red)
                            .padding()
                        Spacer()
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Play Listings 🎾")
            .navigationBarItems(trailing:
                NavigationLink(destination: AddPlayListingView()) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
            )
        }
        .onAppear {
            UITableView.appearance().backgroundColor = UIColor.clear
            if let currentUser = FirebaseManager.shared.currentUser {
                            self.plvm.refresh(user: currentUser)
                        } else {
                            let fallbackUser = User(id: "", uid:"0", email: "", profileImageUrl:"google.com", displayName: "",playStyle:"google.com")
                            self.plvm.refresh(user: fallbackUser)
                        }
        }
    }
    
    private var listingsView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(plvm.combinedListings) { combinedListing in
                    if let user = combinedListing.user {
                        NavigationLink(destination: PlayListingView(plm: PlayListingViewModel(listing: combinedListing.playListing))) {
                            combinedItemView(listing: combinedListing.playListing, user: user)
                        }
                        
                    } else {
                        //listingItemView(listing: combinedListing.playListing)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    @ViewBuilder
    private func combinedItemView(listing: PlayListing, user: User) -> some View {
        HStack(spacing: 15) {
            // User's profile image
            WebImage(url: URL(string: user.profileImageUrl))
                .resizable()
                .indicator(.activity) // Activity Indicator while loading the image
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(user.displayName)
                    .font(.headline)
                    .adaptiveForegroundColor()
                
                // Display listing details
                if let description = listing.description {
                    Text(description)
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                        .lineLimit(2)
                }

                if let listingDate = listing.listingDate {
                    let date = listingDate.dateValue()  // Convert Timestamp to Date
                    let dateString = dateFormatter.string(from: date)  // Convert Date to String

                    Text("Listing date: \(dateString)")
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color.isDarkMode ? .black : .white) //Change color based on Dark Mode
        .cornerRadius(8)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func listingItemView(listing: PlayListing) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Author: \(listing.authorRef.documentID)")
                .font(.subheadline)
                .adaptiveForegroundColor()
                .lineLimit(1)
            
            Text(listing.description ?? "")
                .font(.body)
                .adaptiveForegroundColor()
                .lineLimit(2)
        }
        .padding()
        .background(Color.isDarkMode ? .black : .white) //Change color based on Dark Mode
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
