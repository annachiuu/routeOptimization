//
//  ViewController.swift
//  MapProject
//
//  Created by Anna Chiu on 8/16/17.
//  Copyright © 2017 Anna Chiu. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Alamofire

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, inputVCDelegate {

    
    @IBOutlet weak var myMapView: GMSMapView!
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    
    var mapTasks = MapTasks()
    
    var locationMarker: GMSMarker!
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    
    var markersArray: [GMSMarker] = []
    var wayPointsArray: [String] = []
    
    
    /*/* FOR TESTING PURPOSES --------------------------------------------------------------------------------------  */
        //Put anything in here to test
        func test() {
     
        }
    /* FOR TESTING PURPOSES --------------------------------------------------------------------------------------  */ */
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial setup of Google Maps
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 34.068921, longitude: -118.445181, zoom: 15.0)
        myMapView.camera = camera
        
        // Find my location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() //ask for permission
        
        // Observe for changes in mylocation
        myMapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        
        //GMSMapViewDelegate
        myMapView.delegate = self
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toInputVCPressed(_ sender: Any) {
        performSegue(withIdentifier: "toInputVC", sender: self)
    }
    
    @IBAction func findAddress(_ sender: Any) {
        let addressAlert = UIAlertController(title: "Find Address", message: "Type the address you want to find", preferredStyle: UIAlertControllerStyle.alert)
        
        addressAlert.addTextField { (textField) in
            textField.placeholder = "Address"
        }
        
        let findAction = UIAlertAction(title: "Find", style: UIAlertActionStyle.default) { (alertAction) in
            let address = (addressAlert.textFields![0]).text!
            self.mapTasks.geocodeAddress(address: address, withCompletionHandler: { (status, success) in
                //Handle Success vs Failure
                if !success {
                    print(status)
                    if status == "ZERO_RESULTS" {
                        self.showAlert(title: "Try Different Address", message: "The location could not be found")
                    }
                } else {
                    print("Status is \(status), moving camera....")
                    
                    let coordinate = CLLocationCoordinate2DMake(self.mapTasks.fetchedAddressLat, self.mapTasks.fetchedAddressLong)
                    print(coordinate)
                    self.myMapView.camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 10.0)
                    self.setupLocationMarker(location: coordinate)
                }
            })
        }
        
        let closeAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alertAction) in
        }
        
        addressAlert.addAction(findAction)
        addressAlert.addAction(closeAction)
        
        present(addressAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func createDirections(_ sender: Any) {
        
        let addressAlert = UIAlertController(title: "Find Directions", message: "Please enter origin and destination addresses", preferredStyle: UIAlertControllerStyle.alert)
        
        addressAlert.addTextField { (textField) in
            textField.placeholder = "Origin"
        }
        addressAlert.addTextField { (textField) in
            textField.placeholder = "Destination"
        }
        
        addressAlert.addTextField { (textField) in
            textField.placeholder = "Waypoint1"
        }
        addressAlert.addTextField { (textField) in
            textField.placeholder = "Waypoint2"
        }
        addressAlert.addTextField { (textField) in
            textField.placeholder = "Waypoint3"
        }
        
        let createRouteAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (alertAction) in
            
            if self.originMarker != nil {
                self.clearRoute()
            }
            
            let origin = (addressAlert.textFields?[0].text)!
            let destination = (addressAlert.textFields?[1].text)!
            var arrayWaypoint: [String] = []
            
            for i in 2...4 {
                if addressAlert.textFields?[i].text != "" {
                    arrayWaypoint.append((addressAlert.textFields?[i].text)!)
                }
            }
            
            self.mapTasks.getDirections(origin: origin, destination: destination, waypoints: arrayWaypoint, completionHandler: { (status, success) in
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                } else {
                    print(status)
                }
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alertAction) in
            
        }
        
        addressAlert.addAction(createRouteAction)
        addressAlert.addAction(cancelAction)
        
        present(addressAlert, animated: true, completion: nil)
        
    }

    @IBAction func changeMapType(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Map Types", message: "Select Map Type", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let terrainStyle = UIAlertAction(title: "Terrain", style: UIAlertActionStyle.default) { (alertAction) in
            self.myMapView.mapType = .terrain
        }
        
        let normalStyle = UIAlertAction(title: "Normal", style: UIAlertActionStyle.default) { (alertAction) in
            self.myMapView.mapType = .normal
        }
        
        let hybridStyle = UIAlertAction(title: "Hybrid", style: UIAlertActionStyle.default) { (alertAction) in
            self.myMapView.mapType = .hybrid
        }
        
        let satelliteStyle = UIAlertAction(title: "Satellite", style: UIAlertActionStyle.default) { (alertAction) in
            self.myMapView.mapType = .satellite
        }
        
        let cancelAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) in
            
        }
        
        actionSheet.addAction(normalStyle)
        actionSheet.addAction(terrainStyle)
        actionSheet.addAction(hybridStyle)
        actionSheet.addAction(satelliteStyle)
        actionSheet.addAction(cancelAction)
        
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    //Handle authorization for current location - change myLocationEnabled
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            myMapView.isMyLocationEnabled = true
        }
    }
    
    // Let mylocation appear on map once observed
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation { //if it is currently false, then assign new values for location, camera, myLocationButton and didFindMyLocation
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            myMapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 13.0)
            myMapView.settings.myLocationButton = true
            
            didFindMyLocation = true
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okayAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) in
            
        }
        alert.addAction(okayAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func setupLocationMarker(location: CLLocationCoordinate2D) {
        if locationMarker != nil {
            locationMarker.map = nil
        }
        
        locationMarker = GMSMarker(position: location)
        locationMarker.map = myMapView
        locationMarker.isFlat = false
        locationMarker.title = mapTasks.fetchedFormattedAddress
        locationMarker.snippet = "Treasure"
    }
    

    
    func configureMapAndMarkersForRoute() {
        
        if originMarker != nil {
            originMarker = nil
            destinationMarker = nil
            markersArray = []
        }
        
        
        //Center on origin
        myMapView.camera = GMSCameraPosition.camera(withTarget: self.mapTasks.originCoordinate, zoom: 10.0)
        
        // Mark origin
        originMarker = GMSMarker(position: self.mapTasks.originCoordinate)
        originMarker.map = self.myMapView
        originMarker.icon = GMSMarker.markerImage(with: .blue)
        originMarker.title = self.mapTasks.originAddress
        originMarker.snippet = "Origin"
        
        // Mark Destination
        destinationMarker = GMSMarker(position: self.mapTasks.destinationCoordinate)
        destinationMarker.map = self.myMapView
        destinationMarker.icon = GMSMarker.markerImage(with: .red)
        destinationMarker.title = self.mapTasks.destinationAddress
        destinationMarker.snippet = "Destination"
        
        //Waypoints
        if mapTasks.wayPointsAddresses.count > 0 {
            for i in 0...mapTasks.wayPointsCoordinates.count-1 {
                //converting tap coordinates to lat & long
//                let lat: Double = (waypoint.components(separatedBy: ",")[0] as NSString).doubleValue
//                let lng: Double = (waypoint.components(separatedBy: ",")[1] as NSString).doubleValue
                
                markersArray.append(GMSMarker(position: mapTasks.wayPointsCoordinates[i]!))
                markersArray[i].map = self.myMapView
                markersArray[i].icon = GMSMarker.markerImage(with: .purple)
                markersArray[i].title = self.mapTasks.wayPointsAddresses[i]
                markersArray[i].snippet = "Stop \(i+1)"
                wayPointsArray.append((self.mapTasks.wayPointsAddresses[i]!))

            }
        }
        
        
    }
    
    func drawRoute() {
        // Get route points from JSON
        let route = mapTasks.overviewPolyline["points"] as! String
        // Convert route into GMSPath
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.strokeColor = .black
        routePolyline.strokeWidth = 3
        routePolyline.map = myMapView
    }
    
    func displayRouteInfo() {
        
    }
    
    
    /* ----------------------------- GMSMapViewDelegate ----------------------------------- */
    // Handle tap at coordinate on the map
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
//        if routePolyline != nil {
//            // String representation of coordinate
//            let positionString = String(format: "%f", coordinate.latitude) + "," + String(format: "%f", coordinate.longitude)
//            wayPointsArray.append(positionString)
//            print(wayPointsArray)
//            recreateRoute()
//        }
        
    }
    
    func recreateRoute() {
        if routePolyline != nil {
            clearRoute()
        }
        self.mapTasks.getDirections(origin: mapTasks.originAddress, destination: mapTasks.destinationAddress, waypoints: wayPointsArray) { (status, success) in
            
            if success {
                self.configureMapAndMarkersForRoute()
                self.drawRoute()
                self.displayRouteInfo()
            } else {
                print(status)
            }
        }
    }
    
    func clearRoute() {
        //clear origin and destination markers on map
        originMarker.map = nil
        destinationMarker.map = nil
        routePolyline.map = nil
        
        //clear origin and destination marker data
        originMarker = nil
        destinationMarker = nil
        routePolyline = nil
        
        //clear waypoints markers and data
        if markersArray.count > 0 {
            print("clearing array")
            for marker in markersArray {
                marker.map = nil
            }
            markersArray.removeAll(keepingCapacity: false)
            wayPointsArray.removeAll(keepingCapacity: false)
            mapTasks.wayPointsAddresses.removeAll(keepingCapacity: false)
            mapTasks.wayPointsCoordinates.removeAll(keepingCapacity: false)
        }
        
        
    }
    
    
    /* ----------------------------- InputVCDelegate ----------------------------------- */

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? InputVC {
            destination.delegate = self
        }
    }
    
    func optimizeSelected(origin: String, destination: String, wayPoints: [String]) {
        print("optimizeSelected run. origin: \(origin), destionation: \(destination)")
        
        if self.originMarker != nil {
            self.clearRoute()
        }
        
        var arrayWaypoint: [String] = []
        
        for i in 0...wayPoints.count-1 {
            if wayPoints[i] != "" {
                arrayWaypoint.append((wayPoints[i]))
            }
        }
        
        self.mapTasks.getDirections(origin: origin, destination: destination, waypoints: arrayWaypoint, completionHandler: { (status, success) in
            if success {
                self.configureMapAndMarkersForRoute()
                self.drawRoute()
                self.displayRouteInfo()
            } else {
                print(status)
            }
        })
    }
    
    
    
    
    
    
    
    
    
    
}

