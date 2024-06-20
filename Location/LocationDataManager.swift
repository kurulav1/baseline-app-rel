//
//  LocationDataManager.swift
//  simpl3
//
//  Created by Väinö Kurula on 16.5.2023.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestoreSwift
import CoreLocation
import MapKit

class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var city: String?
    
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            if let location = locationManager.location {
                reverseGeocodeLocation(location)
            }
        }
    }
    
    func distanceInKM(latitude: Double, longitude: Double) -> Double {
            
            let targetCoordinates = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            
        let userCoordinates = CLLocation(latitude: locationManager.location?.coordinate.latitude ?? 50, longitude: locationManager.location?.coordinate.longitude ?? 30)
            let distance = userCoordinates.distance(from: targetCoordinates) / 1000 
            
            let s = String(format: "%.0f", distance)
            
        return Double(s) ?? 0.0
        }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            authorizationStatus = .authorizedWhenInUse
            locationManager.requestLocation()
            break
            
        case .restricted:  // Location services currently unavailable.
            authorizationStatus = .restricted
            break
            
        case .denied:  // Location services currently unavailable.
            authorizationStatus = .denied
            break
            
        case .notDetermined:        // Authorization not determined yet.
            authorizationStatus = .notDetermined
            manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                if let city = placemark.locality {
                    DispatchQueue.main.async { // Update the city on the main queue
                        self.city = city
                    }
                }
            }
        }
        
    }
    
}
