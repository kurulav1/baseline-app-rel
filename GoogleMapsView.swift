//
//  GoogleMapsView.swift
//  simpl3
//
//  Created by Väinö Kurula on 16.5.2023.
//

import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapsView: UIViewRepresentable {
    
     var locationDataManager: LocationDataManager
    
    
    private let zoom: Float = 15.0
    
    func makeUIView(context: Self.Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: (locationDataManager.locationManager.location?.coordinate.latitude)!, longitude: (locationDataManager.locationManager.location?.coordinate.longitude)!, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        let camera = GMSCameraPosition.camera(withLatitude: (locationDataManager.locationManager.location?.coordinate.latitude)!, longitude: (locationDataManager.locationManager.location?.coordinate.longitude)!, zoom: 6.0)
        mapView.camera = camera
        mapView.animate(toLocation: CLLocationCoordinate2D(latitude:(locationDataManager.locationManager.location?.coordinate.latitude)!, longitude: (locationDataManager.locationManager.location?.coordinate.longitude)!))
    }
}

