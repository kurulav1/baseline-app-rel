//
//  ProfileView.swift
//  simpl3
//
//  Created by Väinö Kurula on 10.5.2023.
//
// view to see your own profile

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestoreSwift
import CoreLocation
import MapKit

class ProfileViewModel: ObservableObject {
    @Published var user = FirebaseManager.shared.auth.currentUser
    @Published var errorMessage = ""
    @Published var isCurrentlyLoggedOut = false
    @Published var playStyle = ""
    @Published var displayName = ""
    @Published var ownProfileImageUrl = ""
    @StateObject var locationDataManager = LocationDataManager()
    @Published var latitude = ""
    @Published var longitude = ""
    
    init() {
            FirebaseManager.shared.auth.addStateDidChangeListener { [weak self] (auth, user) in
                self?.user = user
                self?.fetchUserData()
            }
        }
    
    func fetchUserData() {
        guard let uid = user?.uid else {
            print("User is not logged in")
            return
        }
        
        let db = FirebaseManager.shared.firestore
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("User data not found")
                return
            }
            
            let data = document.data()
            self.playStyle = data?["playStyle"] as? String ?? ""
            self.displayName = data?["displayName"] as? String ?? ""
            self.ownProfileImageUrl = data?["profileImageUrl"] as? String ?? ""
        }
    }
    
    func updateUserData() {
        guard let uid = user?.uid else {
            print("User is not logged in")
            return
        }
        
        let db = FirebaseManager.shared.firestore
        let docRef = db.collection("users").document(uid)
        
        let updatedData: [String: Any] = [
            "playStyle": playStyle,
            "displayName": displayName
        ]
        
        docRef.updateData(updatedData) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
                return
            }
            
            print("User data updated")
        }
    }
    
    func clearUserData() {
        playStyle = ""
        displayName = ""
        ownProfileImageUrl = ""
        latitude = ""
        longitude = ""
    }
}

struct ProfileView: View {
    @ObservedObject var pm = ProfileViewModel()
    @StateObject var locationDataManager = LocationDataManager()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.4300, longitude: -122.1700),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    @State private var isShowingImagePicker = false
    @State private var selectedImage: UIImage?
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Group {
                        if let url = URL(string: pm.ownProfileImageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                                .foregroundColor(.gray) // Placeholder icon color
                                .shadow(radius: 5)
                        }
                    }
                    .onTapGesture {
                        self.isShowingImagePicker = true
                    }
                    .sheet(isPresented: $isShowingImagePicker) {
                        ImagePicker(image: self.$selectedImage)
                    }
                    
                    Group {
                        Section(header: Text("User Details")) {
                            ProfileField(title: "Your ID", value: pm.user?.uid ?? "LAZ6cmgEaCRK8ZSyQE49Eoqk3732")
                            ProfileField(title: "Your Email", value: pm.user?.email ?? "none")
                            TextField("Your Playstyle", text: $pm.playStyle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Your Display Name", text: $pm.displayName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Section(header: Text("Location")) {
                            switch locationDataManager.locationManager.authorizationStatus {
                            case .authorizedWhenInUse:
                                LocationDetailsView(locationDataManager: locationDataManager)
                            case .restricted, .denied:
                                Text("Location services are restricted or denied.")
                            case .notDetermined:
                                Text("Finding your location...")
                                    .padding(.vertical)
                                    .progressViewStyle(CircularProgressViewStyle())
                            default:
                                ProgressView()
                            }
                        }
                        
                        Section(header: Text("Map")) {
                            GoogleMapsView(locationDataManager: locationDataManager)
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button(action: {
                pm.updateUserData()
            }) {
                Text("Save")
            })
            .onAppear {
                pm.fetchUserData() // Fetch user data when the view appears
            }
            .onChange(of: selectedImage) { newImage in
                if let newImage = newImage {
                    uploadProfilePicture(image: newImage)
                }
            }
        }
        
    }
    
    func uploadProfilePicture(image: UIImage) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("User is not logged in")
            return
        }
        
        let ref = FirebaseManager.shared.storage.reference(withPath: "profilePictures/\(uid)")
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Could not convert image to data")
            return
        }
        
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image to Storage: \(error.localizedDescription)")
                return
            }
            
            ref.downloadURL { url, error in
                if let error = error {
                    print("Error retrieving download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let url = url else {
                    print("Download URL is nil")
                    return
                }
                
                // Update user document with new profile picture URL
                let db = FirebaseManager.shared.firestore
                let docRef = db.collection("users").document(uid)
                docRef.updateData(["profileImageUrl": url.absoluteString]) { error in
                    if let error = error {
                        print("Error updating user data: \(error.localizedDescription)")
                        return
                    }
                    
                    print("User data updated with new profile picture")
                    pm.ownProfileImageUrl = url.absoluteString // update the UI
                }
            }
        }
    }
    
    struct ProfileField: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                TextField("", text: .constant(value))
                    .disabled(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.vertical, 4)
        }
    }
    
    struct LocationDetailsView: View {
        @ObservedObject var locationDataManager: LocationDataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Current Location")
                    .font(.headline)
                Text("Latitude: \(locationDataManager.locationManager.location?.coordinate.latitude.description ?? "Error loading")")
                Text("Longitude: \(locationDataManager.locationManager.location?.coordinate.longitude.description ?? "Error loading")")
                Text(locationDataManager.city ?? "Error in approximating region")
            }
        }
    }
}
