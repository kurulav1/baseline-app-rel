//
//  AddPlayListingView.swift
//  simpl3
//
//  Created by Väinö Kurula on 28.5.2023.
//

import SwiftUI
import FirebaseFirestore
import FirebaseCore


import SwiftUI
import FirebaseFirestore
import FirebaseCore

struct AddPlayListingView: View {
    @State private var listingDate: Date?
    @State private var description = ""
    @State private var showingConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @StateObject var locationData = LocationDataManager()
    
    var formattedListingDate: Date {
        listingDate ?? Date()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    DatePicker(selection: Binding(
                        get: { formattedListingDate },
                        set: { listingDate = $0 }
                    ), displayedComponents: .date) {
                        Text("Listing Date")
                    }

                    Button(action: addPlayListing) {
                        Text("Add Listing")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(title: Text("Success"), message: Text("Listing added successfully."), dismissButton: .default(Text("OK")) {
                    self.dismiss()
                })
            }
            .navigationTitle("Add Play Listing")
        }
    }

    func addPlayListing() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Error: Current user UID not found.")
            return
        }

        let userRef = FirebaseManager.shared.firestore.collection("users").document(uid)

        let data: [String: Any] = [
            "authorUid": uid,
            "authorRef": userRef,
            "description": description,
            "listingDate": Timestamp(date: formattedListingDate), // Convert the listingDate to a Firestore Timestamp
            "city": locationData.city ?? "Unknown" 
        ]

        let collection = FirebaseManager.shared.firestore.collection("play_listing")
        collection.addDocument(data: data) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added successfully.")
                self.showingConfirmation = true
            }
        }
    
    }
}
