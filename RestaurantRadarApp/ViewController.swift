//
//  ViewController.swift
//  RestaurantRadarApp
//
//  Created by Антон Калинин on 05.06.2020.
//  Copyright © 2020 Kalinin. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet var mapView: MKMapView!
    
    var currentTransportType: MKDirectionsTransportType = .automobile
    var currentPlacemark: CLPlacemark?
    var currentRoute: MKRoute?
    let locationManager = CLLocationManager()
    
    let restauranrString = "Restaurant"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        
        // Request for a user's authorization for location services
        locationManager.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        
        currentLocation()
        mapView.delegate = self
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
            mapView.showsScale = true
            mapView.showsTraffic = true
        }
    }
    
    
//    @IBAction func showDirection(_ sender: Any) {
//        guard let currentPlacemark = currentPlacemark else {
//            return
//        }
//        
//        switch segmentedControl.selectedSegmentIndex {
//        case 0: currentTransportType = .automobile
//        case 1: currentTransportType = .walking
//        default: break
//        }
//        
//        segmentedControl.isHidden = false
//        
//        let directionRequest = MKDirections.Request()
//        
//        // Set the source and destination of the route
//        directionRequest.source = MKMapItem.forCurrentLocation()
//        let destinationPlacemark = MKPlacemark(placemark: currentPlacemark)
//        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
//        directionRequest.transportType = currentTransportType
//        
//        // Calculate the direction
//        let directions = MKDirections(request: directionRequest)
//        directions.calculate { (routeResponse, routeError) in
//            guard let routeResponse = routeResponse else {
//                if let routeError = routeError {
//                    print("Error: \(routeError)")
//                }
//                return
//            }
//            
//            let route = routeResponse.routes[0]
//            self.currentRoute = route
//            self.mapView.removeOverlays(self.mapView.overlays)
//            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
//            let rect = route.polyline.boundingMapRect
//            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
//        }
//    }
    
    
    @IBAction func showNearby(sender: UIButton) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "restaurant"
        searchRequest.region = mapView.region
        
        let localSearch = MKLocalSearch(request: searchRequest)
        
        localSearch.start { response, error  in
            
            guard let response = response else {
                if let error = error {
                    print(error)
                }
                return
            }
            
            let mapItems = response.mapItems
            let nearbyAnnotation: MKPointAnnotation = MKPointAnnotation()
            
            if mapItems.count > 0 {
                var minDistance: Double = Double.greatestFiniteMagnitude
                if let location = self.locationManager.location {
                    for item in mapItems {
                        if let min = item.placemark.location?.distance(from: location), minDistance >= min {
                            minDistance = min
                            nearbyAnnotation.title = item.name
                            nearbyAnnotation.subtitle = item.phoneNumber
                            
                            self.currentPlacemark = item.placemark
                            
                            if let location = item.placemark.location {
                                nearbyAnnotation.coordinate = location.coordinate
                            }
                        }
                    }
                } else {
                    let item = mapItems.first!
                    
                    nearbyAnnotation.title = item.name
                    nearbyAnnotation.subtitle = item.phoneNumber
                    
                    self.currentPlacemark = item.placemark
                    
                    if let location = item.placemark.location {
                        nearbyAnnotation.coordinate = location.coordinate
                    }
                }
                
            }
            
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.showAnnotations([nearbyAnnotation], animated: true)
        }
    }
 
    @IBAction func tracking(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    // MARK: - MKMapViewDelegate methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MyPin"
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        // Reuse the annotation if possible
        var annotationView: MKPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        }
        
        if let currentPlacemarkCoordinate = currentPlacemark?.location?.coordinate {
            if currentPlacemarkCoordinate.latitude == annotation.coordinate.latitude && currentPlacemarkCoordinate.longitude == annotation.coordinate.longitude {
                let leftIconView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 53, height: 53))
                annotationView?.leftCalloutAccessoryView = leftIconView
                
                // Pin color customization
                if #available(iOS 9.0, *) {
                    annotationView?.pinTintColor = .orange
                }
            } else {
                // Pin color customization
                if #available(iOS 9.0, *) {
                    annotationView?.pinTintColor = .red
                }
            }
        }
        
        annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return annotationView
    }
    
    func currentLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        } else {
            // Fallback on earlier versions
        }
        locationManager.startUpdatingLocation()
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last! as CLLocation
        let currentLocation = location.coordinate
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 800, longitudinalMeters: 800)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

