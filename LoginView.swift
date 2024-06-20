//
//  LoginView.swift
//  simpl3
//
//  Created by Väinö Kurula on 7.5.2023.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import FirebaseAuth
import FirebaseStorage

struct ConfigurationView: View {
    @Binding var profileImageUrl: String
        @Binding var displayName: String
        @Binding var playStyle: String
        @Binding var selectedImage: UIImage?
        let completion: () -> Void // Closure to handle configuration completion

        @State private var isImagePickerShown = false

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .onTapGesture {
                            self.isImagePickerShown = true
                        }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .onTapGesture {
                            self.isImagePickerShown = true
                        }
                }
                TextField("Display Name", text: $displayName)
            }

            Section(header: Text("Play Style")) {
                TextField("Play Style", text: $playStyle)
            }

            Section {
                Button(action: {
                    // Call the completion closure when the user taps the "OK" button
                    completion()
                }) {
                    Text("OK")
                }
                .disabled(displayName.isEmpty || playStyle.isEmpty) // Disable the button until all fields are filled
            }
        }
        .sheet(isPresented: $isImagePickerShown, content: {
            ImagePicker(image: $selectedImage)
                })
        .navigationTitle("Configuration")
    }
}


struct LoginView: View {
    let didCompleteLoginProcess: () -> ()

        @State private var isLoginMode = false
        @State private var email = ""
        @State private var password = ""
        @State private var profileImageUrl = ""
        @State private var displayName = ""
        @State private var playStyle = ""
        @State private var selectedImage: UIImage?
        @StateObject private var locationDataManager = LocationDataManager()

        @Environment(\.colorScheme) var colorScheme

        @State private var showConfiguration = false

    private func handleConfigurationCompletion() {
        if let selectedImage = selectedImage {
            uploadProfileImage(image: selectedImage) { [self] (url, error) in
                if let url = url {
                    self.profileImageUrl = url.absoluteString
                    self.storeUserInformation()
                    showConfiguration = false
                } else {
                    print("Failed to upload profile image: \(error?.localizedDescription ?? "No error description")")
                }
            }
        } else {
            self.storeUserInformation()
            showConfiguration = false
        }
    }
    
    private func handleAction() {
            if isLoginMode {
                loginUser()
            } else {
                showConfiguration = true
                createNewAccount()
            }
        }

        // Helper function to convert a User object to a [String: Any] dictionary
        func userToDictionary(user: User) -> [String: Any] {
            let data: [String: Any] = [
                "uid": user.uid,
                "email": user.email,
                "profileImageUrl": user.profileImageUrl,
                "displayName": user.displayName,
                "playStyle": user.playStyle
            ]
            return data
        }



    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Picker(selection: $isLoginMode, label: Text("Login picker")) {
                    Text("Login")
                        .tag(true)
                    Text("Register")
                        .tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .foregroundColor(.primary)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .foregroundColor(.primary)

                Button(action: {
                    loginGoogle()
                }) {
                    HStack {
                        Spacer()
                        Text("Google login")
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Button(action: {
                    handleAction()
                }) {
                    HStack {
                        Spacer()
                        Text(isLoginMode ? "Log In" : "Register")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Text(loginStatusMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .sheet(isPresented: $showConfiguration) {
                ConfigurationView(
                    profileImageUrl: $profileImageUrl,
                    displayName: $displayName,
                    playStyle: $playStyle,
                    selectedImage: $selectedImage,
                    completion: handleConfigurationCompletion
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showConfiguration = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if #available(iOS 15.0, *) {
                UIScrollView.appearance().keyboardDismissMode = .interactive
            }
        }
    }
    
    @State private var loginStatusMessage = ""

    private func loginGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        if let presentingViewController = UIApplication.shared.keyWindow?.rootViewController {
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [self] result, error in
                guard error == nil else {
                    print("Error in Google sign in")
                    return
                }

                guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

                FirebaseManager.shared.auth.signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Failed to login: \(error.localizedDescription)")
                        return
                    }
                    self.email = result!.user.profile!.email
                    
                    
                    let uid = authResult!.user.uid
                    let usersRef = FirebaseManager.shared.firestore.collection("users")
                    
                    usersRef.document(uid).getDocument { (document, error) in
                        if let document = document, document.exists {
                            // User entry exists, no need to create a new one
                            print("User entry already exists in Firestore")
                            storeUserLocation()
                            didCompleteLoginProcess()
                            
                        } else {
                            // User entry does not exist, set showConfiguration to true
                            // User entry will be created in handleConfigurationCompletion
                            showConfiguration = true
                        }
                    }
                }
            }
        }
    }


    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login...")
                loginStatusMessage = "Failed to login..."
                return
            }
            print("User is: \(FirebaseManager.shared.auth.currentUser?.email ?? "err")")
            loginStatusMessage = "Login successful"
            storeUserLocation()
            didCompleteLoginProcess()
        }
    }

    private func storeUserLocation() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let latitude = locationDataManager.locationManager.location?.coordinate.latitude
        let longitude = locationDataManager.locationManager.location?.coordinate.longitude
        let userLocation = [FirebaseConstants.uid: uid, FirebaseConstants.latitude: latitude!, FirebaseConstants.longitude: longitude!] as [String : Any]
        let userLocationsCollection = FirebaseManager.shared.firestore.collection(FirebaseConstants.userLocations)
        userLocationsCollection.document(uid).setData(userLocation) { err in
            if let err = err {
                print(err)
                loginStatusMessage = "Error in storing location..."
                return
            }
            print("Successfully stored location")
        }
    }

    private func createNewAccount() {
            FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
                if let err = err {
                    print("Failed to register...")
                    loginStatusMessage = "Failed to register..."
                    return
                }

                loginStatusMessage = "Registration successful"

                // Define the completion handler before `configurationView`
                let configurationCompletion: () -> Void = { [self] in
                    if let selectedImage = selectedImage {
                        uploadProfileImage(image: selectedImage) { (url, error) in
                            if let url = url {
                                self.profileImageUrl = url.absoluteString
                                self.storeUserInformation()
                            } else {
                                print("Failed to upload profile image: \(error?.localizedDescription ?? "No error description")")
                            }
                        }
                    } else {
                        self.storeUserInformation()
                    }
                }

                // Present ConfigurationView
                let configurationView = ConfigurationView(profileImageUrl: $profileImageUrl, displayName: $displayName, playStyle: $playStyle, selectedImage: $selectedImage, completion: configurationCompletion)

                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    let hostingController = UIHostingController(rootView: configurationView)
                    rootViewController.present(hostingController, animated: true, completion: nil)
                }
            }
        }
    
    func uploadProfileImage(image: UIImage, completion: @escaping (URL?, Error?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to convert image to data"]))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let profileImagesRef = storageRef.child("profile_images/\(UUID().uuidString).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        profileImagesRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(nil, error)
            } else {
                profileImagesRef.downloadURL { (url, error) in
                    completion(url, error)
                }
            }
        }
    }

    private func storeUserInformation() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = [FirebaseConstants.email: email, FirebaseConstants.uid: uid, FirebaseConstants.profileImageUrl: profileImageUrl, "displayName": displayName, "playStyle": playStyle]
        FirebaseManager.shared.firestore.collection(FirebaseConstants.users)
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    loginStatusMessage = "Error in storing info..."
                    return
                }
                print("Successfully stored info")
            }
    }
    
}


