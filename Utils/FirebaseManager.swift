//
//  FirebaseManager.swift
//  simpl3
//
//  Created by Väinö Kurula on 7.5.2023.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import GoogleMaps
import GooglePlaces
import GoogleSignIn

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    var currentUser: User?
    static let shared = FirebaseManager()
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        GMSServices.provideAPIKey("")
        GMSPlacesClient.provideAPIKey("")
        super.init()
    }
}
