//
//  ViewController.swift
//  Auto Layout Calculator
//
//  Created by amir reza mostafavi on 12/26/17.
//  Copyright © 2017 Amir Mostafavi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var billLabel: UILabel!
    @IBOutlet weak var decimalButton: UIButton!
    @IBOutlet weak var popUp: UIView!
    @IBOutlet weak var roundUpButton: UIButton!
    
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var darkLayer: UIView!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    var rounded: Bool = false
    var tip: Double = 0;
    var tot: Double = 0;
    
    @IBOutlet weak var popUpBottomConst: NSLayoutConstraint!
    let LOCATION_DATABASE_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "7e4baeafe623717fddbfa94c3b2d991d"
    
    var locationManager: CLLocationManager?
    var currentNumber: Double = 0
    var placesAfterDecimal = 0
    var decimalPressed = false
    var currentCountry: String = "US"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getLocation()
        alertLabel.isHidden = true
        popUpBottomConst.constant = -325
        darkLayer.isHidden = true
        popUp.layer.shadowOpacity = 1
        popUp.layer.shadowRadius = 6
        billLabel.text = "0"
        clearButton.isHidden = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func numberPressed(_ sender: AnyObject) {
        print(sender.tag)
        updateCurrentNumber(decimalPressed, pressedNumber: Int(sender.tag))
        updateLabel()
    }
    
    @IBAction func decimalPressed(_ sender: Any) {
        billLabel.text = "\(Int(currentNumber))."
        decimalPressed = true
        decimalButton.isEnabled = false
    }
    
    @IBAction func clearButtonPressed(_ sender: Any) {
        resetEverything()
        updateLabel()
    }
    
    func getLocation() {
        if locationManager == nil {
            
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager?.startUpdatingLocation()
        } else if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager?.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .denied {
            print("User denied location permissions.")
        }
    }
    
    @IBAction func showTotalButtonPressed(_ sender: AnyObject) {
        getLocation()
        if currentNumber == 0 {
            let alert = UIAlertController(title: "invalid bill amount", message: "Please enter your bill amount", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Got it", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        } else {
            let data = TipDataModel(currentCountry: currentCountry, enteredBillAmount: currentNumber)
            let quality = sender.tag
            data.getTipPercentage(quality: quality!)
            data.getTipAmount()
            data.getTotal()
            let tipPercentage = Int(data.tipPercentage * 100)
            let tipAmount = data.tipAmmout
            tip = tipAmount
            let total = data.total
            tot = total
            let alert = data.alert
            let flagEmoji = countryCodeToFlag(country: currentCountry)
//            showTotalAndTipAlert(total: String(total) , tip: String(tipAmount), flagEmoji: flagEmoji, message: "")
            showPopUp(flag: flagEmoji, tipPercentage: tipPercentage,tipAmount: tipAmount, total: total, alert: alert)
            data.clear()
        }
    }
    
    @IBAction func closePopUp(_ sender: Any) {
        hidePopUp()
        rounded = false
    }
    
    
    
    
    func updateCurrentNumber(_ decimalPressed: Bool, pressedNumber: Int) {
        if !decimalPressed {
            currentNumber *= 10
            currentNumber += Double(pressedNumber)
        } else {
            placesAfterDecimal += 1
            currentNumber += (Double(pressedNumber) / pow(10.0, Double(placesAfterDecimal)))
        }
    }
    
    func updateLabel() {
        billLabel.text = "\(String(format: "%.\(placesAfterDecimal)f", currentNumber))"
        if currentNumber != 0 {
            clearButton.isHidden = false
        } else {
            clearButton.isHidden = true
        }
    }
    
    func resetEverything() {
        currentNumber = 0
        placesAfterDecimal = 0
        decimalPressed = false
        decimalButton.isEnabled = true
         clearButton.isHidden = true
    }
    
    //MARK: - Location Manager Functions
    /***************************************************************/
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager!.stopUpdatingLocation()
            locationManager!.delegate = nil
            let longitude = String(location.coordinate.longitude)
            let latitude = String(location.coordinate.latitude)
            let params: [String : String] = ["lat": latitude, "lon": longitude, "appid": APP_ID]
            getCountry(url: LOCATION_DATABASE_URL, parameters: params)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        let alert = UIAlertController(title: "Location Unavailable", message: "We were unable to find your location! Default country is set to US", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    func getCountry(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success! Got the country")
                let countryJSON: JSON = JSON(response.result.value!)
                self.updateCountryData(json: countryJSON)
            } else {
                self.showConnectionIssueAlert()
            }
        }
    }
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
    func updateCountryData(json: JSON) {
        if let country = json["sys"]["country"].string {
            currentCountry = country
        } else {
            showConnectionIssueAlert()
        }
    }
    
    //MARK: - Helper Methods
    /***************************************************************/
    func showConnectionIssueAlert() {
        let alert = UIAlertController(title: "Connection Issues", message: "We were unable to contact the server! Default country is set to US", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func countryCodeToFlag(country:String) -> String {
        let base = 127397
        var usv = String.UnicodeScalarView()
        for i in country.utf16 {
            usv.append(UnicodeScalar(base + Int(i))!)
        }
        return String(usv)
    }
    
//    func updateTipDataModel(updateAll: Bool) {
//        if updateAll {
//            tipData.billAmount = currentNumber
//            tipData.getTipPercentage()
//            tipData.getTipAmount()
//            tipData.getTotal()
//        } else {
//            tipData.getTipAmount()
//            tipData.getTotal()
//        }
//    }
    
    func showPopUp(flag: String, tipPercentage: Int ,tipAmount: Double, total: Double, alert: Bool){
        if alert {
            alertLabel.isHidden = false
        }
        flagLabel.text = flag
        percentageLabel.text = "(%\(tipPercentage))"
        tipLabel.text = String(format: "%.2f", tipAmount)
        totalLabel.text = String(format: "%.2f", total)
        popUpBottomConst.constant = -20
        darkLayer.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func roundTotalPressed(_ sender: Any) {
        if(!rounded){
            let roundedTotal = tot.rounded(.up)
            let change = roundedTotal - tot
            let newTip = tip + change
            tipLabel.text = String(format: "%.2f", newTip)
            totalLabel.text = String(format: "%.2f", roundedTotal)
            roundUpButton.setTitle("Undo", for: .normal)
        } else {
            tipLabel.text = String(format: "%.2f", tip)
            totalLabel.text = String(format: "%.2f", tot)
            roundUpButton.setTitle("Round total", for: .normal)
        }
        rounded = !rounded
    }
    
    func hidePopUp(){
        popUpBottomConst.constant = -325
        darkLayer.isHidden = true
        alertLabel.isHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    
    func showDontTipInCountryAlert(billAmount: Double, flagEmoji: String) {
        let alert = UIAlertController(title: "Total plus tip = \(billAmount)", message: "Leaving tip in \(flagEmoji) is not usual. (🚨 May not be appropriate   to leave tip)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Got it", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showTotalAndTipAlert(total: String, tip: String, flagEmoji: String, message: String) {
        let alert = UIAlertController(title: "\(flagEmoji)\nTotal plus tip = \(total)", message: "\(message) you can leave \(tip) currency for tip", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Got it", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

