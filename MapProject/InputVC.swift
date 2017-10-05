//
//  InputVC.swift
//  MapProject
//
//  Created by Anna Chiu on 8/23/17.
//  Copyright © 2017 Anna Chiu. All rights reserved.
//


/* TO DO LIST */
/*
 - Show add button only when the cell has an address
 
 */

protocol inputVCDelegate {
    func optimizeSelected(origin: String, destination: String, wayPoints: [String])
}

import UIKit

class InputVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var originTF: UITextField!
    @IBOutlet weak var destinationTF: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: inputVCDelegate? = nil
    var waypointsAddresses: [String] = []
    
    @IBAction func addWaypointPressed(_ sender: Any) {
        print("Adding new WayPoint...")
        waypointsAddresses.append("")
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        waypointsAddresses.append("")
    }
    
    @IBAction func Optimize(_ sender: Any) {
        
        appendAddressesToArray()
        for i in 0...waypointsAddresses.count-1 {
            print(waypointsAddresses[i])
        }
        
        if (originTF != nil && destinationTF != nil) {
            print("origin & destination filled...")
            self.delegate?.optimizeSelected(origin: originTF.text!, destination: destinationTF.text!, wayPoints: waypointsAddresses)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return waypointsAddresses.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let inputCell = tableView.dequeueReusableCell(withIdentifier: "waypointsCell") as? waypointsCell {
                inputCell.waypointTF.placeholder = "Stop \(indexPath.row+1)"
                return inputCell
            } else {
                return UITableViewCell()
            }
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addWaypointsCell")
            return cell!
        }
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("additional calculations...")
    }
    
    func appendAddressesToArray() {
        //append addresses into waypointsaddresses array
        var i = 0
        for cell in tableView.visibleCells{
            if let inputCell = cell as? waypointsCell {
                if let address = inputCell.waypointTF.text {
                    waypointsAddresses[i] = address
                    i += 1
                }
            }
        }
    }
    
    
}
