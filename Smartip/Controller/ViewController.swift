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
    
    @IBOutlet weak var clearButton: UIButton!
    
    let LOCATION_DATABASE_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "7e4baeafe623717fddbfa94c3b2d991d"
    
    var locationManager: CLLocationManager?
    var currentNumber: Double = 0
    var placesAfterDecimal = 0
    var decimalPressed = false
    var tipData = TipDataModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //getLocation()
        billLabel.text = "0"
        clearButton.isHidden = true
        // Do any additional setup after loading the view, typically from a nib.
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
            updateTipDataModel(updateAll: true)
            let country = tipData.country
            let flagEmoji = countryCodeToFlag(country: country)
            var total = tipData.total
            var tipAmount = tipData.tipAmmout
            if tipData.tipPercentage == 0 {
                showDontTipInCountryAlert(billAmount: tipData.billAmount, flagEmoji: flagEmoji)
            } else {
                var qualityMessage = "Seems like service was not great and was not too bad either."
                if sender.tag == 1 {
                    qualityMessage = "Seems like service was not amazing."
                    tipData.tipPercentage -= 0.03
                } else if sender.tag == 3 {
                    qualityMessage = "Seems like service was amazing!"
                    tipData.tipPercentage += 0.03
                }
                updateTipDataModel(updateAll: false)
                total = tipData.total
                tipAmount = tipData.tipAmmout
                let totalWith2Decimal = "\(String(format: "%.2f", total))"
                let tipWith2Decimal = "\(String(format: "%.2f", tipAmount))"
                showTotalAndTipAlert(total: totalWith2Decimal, tip: tipWith2Decimal, flagEmoji: flagEmoji, message: qualityMessage)
            }
        }
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
                print(response.result.value!)
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
            print(country)
            tipData.country = country
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
    
    func updateTipDataModel(updateAll: Bool) {
        if updateAll {
            tipData.billAmount = currentNumber
            tipData.getTipPercentage()
            tipData.getTipAmount()
            tipData.getTotal()
        } else {
            tipData.getTipAmount()
            tipData.getTotal()
        }
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

