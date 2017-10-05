//
//  MapTasks.swift
//  MapProject
//
//  Created by Anna Chiu on 8/17/17.
//  Copyright © 2017 Anna Chiu. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation

class MapTasks: NSObject {
    
    override init() {
        super.init()
        
    }
    
    // Geocode one address and return coordinates
    /************************************************************************************/
    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
    var lookupAddressResults: [String: Any]?
    var fetchedFormattedAddress: String!
    var fetchedAddressLong: Double!
    var fetchedAddressLat: Double!
    
    
    
    //         Convert URL String to URL
    func geocodeAddress(address: String!, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        
        if let lookupAddress = address {
            let geocodeURLString = baseURLGeocode + "address=" + lookupAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let geocodeURL = URL(string: geocodeURLString)
            Alamofire.request(geocodeURL!, method: .get).responseJSON { (response) in
                switch(response.result) {
                case .failure(_):
                    print(response.result.error)
                    completionHandler("Invalid Address", false)
                    break
                    
                case .success(_):
                    if let result = response.result.value {
                        let dict = result as! NSDictionary
                        
                        let status = dict["status"] as! String
                        
                        if status == "OK" {
                            let allResults = dict["results"] as! [[String: Any]]
                            self.lookupAddressResults = allResults[0]
                            
                            //fill in other values from dictionary of first result
                            self.fetchedFormattedAddress = self.lookupAddressResults?["formatted_address"] as! String
                            let geometry = self.lookupAddressResults?["geometry"] as! [String: Any]
                            self.fetchedAddressLong = (geometry["location"] as! [String: Any])["lng"] as! Double!
                            self.fetchedAddressLat = (geometry["location"] as! [String: Any])["lat"] as! Double!
                            completionHandler(status, true)
                        } else {
                            completionHandler(status, false)
                        }
                    }
                }
            }
        }
    }
    /************************************************************************************/
    
    
    
    // Geocode coordinates and find directions between two addresses
    /************************************************************************************/
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    var selectedRoute: [String: Any]!
    var overviewPolyline: [String: Any]!
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var wayPointsCoordinates: [CLLocationCoordinate2D?] = []
    var wayPointsAddresses: [String?] = []
    
    
    
    func getDirections(origin: String!, destination: String!, waypoints: [String]!, completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        if let originLocation = origin {
            if let destinationLocation = destination {
                
                var directionsURLString = ""
                
                
                if waypoints.count == 0 {
                    directionsURLString = baseURLDirections + "origin=" + originLocation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "&destination=" + destinationLocation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                } else {
                    
                    var wayPointsString = ""
                    for waypoint in waypoints {
                        wayPointsString += "|" + waypoint
                    }
                    
                    directionsURLString = baseURLDirections + "origin=" + originLocation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! +  "&waypoints=optimize:true" + wayPointsString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "&destination=" + destinationLocation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                }
                
                guard let directionsURL = URL(string: directionsURLString) else {
                    fatalError("Failed to create URL")
                }
                
                
                //Alamofire request
                Alamofire.request(directionsURL, method: .get).responseJSON(completionHandler: { (response) in
                    switch(response.result) {
                    case.failure(_):
                        print(response.result.error)
                        completionHandler("",false)
                        break
                    case.success(_):
                        if let result = response.result.value {
                            let dict = result as! NSDictionary
                            
                            let status = dict["status"] as! String //Check for status
                            
                            //If status is OK then...
                            if status == "OK" {
                                //store routes and choose the first one
                                self.selectedRoute = (dict["routes"] as! [[String: Any]])[0]
                                self.overviewPolyline = self.selectedRoute["overview_polyline"] as! [String: Any]
                                
                                //Array of legs
                                let legs = self.selectedRoute["legs"] as! [[String: Any]]
                                //First leg's start location = originalLocation
                                if let startLocationDict = legs[0]["start_location"] as! [String: Any]? {
                                    self.originCoordinate = CLLocationCoordinate2DMake(startLocationDict["lat"] as! Double!, startLocationDict["lng"] as! Double!)
                                    //Last leg's end location = destinationLocation
                                    if let endLocationDict = legs[legs.count - 1]["end_location"] as! [String: Any]? {
                                        self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDict["lat"] as! Double!, endLocationDict["lng"] as! Double!)
                                        
                                        
                                        // Parse coordinates for waypoints and append to array
                                        if waypoints.count > 0 {
                                            for i in 0...waypoints.count-1 {
                                                if let waypointDict = legs[i]["end_location"] as! [String: Any]? {
                                                    //Append waypoint coordinate
                                                    self.wayPointsCoordinates.append(CLLocationCoordinate2DMake(waypointDict["lat"] as! Double, waypointDict["lng"] as! Double))
                                                    //Append waypoint address
                                                    self.wayPointsAddresses.append(legs[i]["end_address"] as! String)
                                                } else {
                                                    print("Waypoint \(i+1) went wrong")
                                                }
                                        }
                                    }
                                    } else {
                                        print("end location went wrong")
                                    }
                                } else {
                                    print("start location went wrong")
                                    
                                }
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[0]["end_address"] as! String
                                
                                print(self.originAddress)
                                print(self.destinationAddress)
                                
                                //loop waypoints and print waypoints addresses as well
                                if waypoints.count > 0 {
                                    for i in 0...waypoints.count-1 {
                                        print(self.wayPointsAddresses[i])
                                    }
                                }
                                
                                self.calculateTotalDistanceAndDuration()
                                
                                completionHandler(status, true)
                            } else {
                                completionHandler(status, false)
                            }
                        }
                        break
                    }
                })
            } else {
                completionHandler("Destination is nil", false)
            }
        } else {
            completionHandler("Origin is nil", false)
        }
        
    }
    
    
    //Calculate total distance and time
    var totalDistanceInMeters: UInt = 0
    var totalDistance: String!
    var totalDurationInSeconds: UInt = 0
    var totalDuration: String!
    
    func calculateTotalDistanceAndDuration() {
        let legs = self.selectedRoute["legs"] as! [[String: Any]]
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        
        //total the distance and duration
        for leg in legs {
            totalDistanceInMeters += (leg["distance"] as! [String: Any])["value"] as! UInt
            totalDurationInSeconds += (leg["duration"] as! [String: Any])["value"] as! UInt
        }
        
        let distanceInMiles: Double = Double(totalDistanceInMeters/1609)
        let totalDistance = "Total Distance: \(distanceInMiles)"
        
        let mins = totalDurationInSeconds / 60
        let hours = mins / 60
        let days = hours / 24
        let remainingHours = hours % 24
        let remainingMins = mins % 60
        let remainingSecs = totalDurationInSeconds % 60
        
        totalDuration = "Duration \(days)d \(remainingHours)h \(remainingMins)m \(remainingSecs)s"
        print(totalDuration)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /************************************************************************************/
    
}
