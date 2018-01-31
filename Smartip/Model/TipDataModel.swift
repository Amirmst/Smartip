//
//  TipDataModel.swift
//  Auto Layout Calculator
//
//  Created by amir reza mostafavi on 1/3/18.
//  Copyright © 2018 Amir Mostafavi. All rights reserved.
//

import UIKit

class TipDataModel {
    var countriesAndTips: [String : Double] = ["US" : 17/100, "FR" : 10/100]
    var alert = false
    var billAmount: Double = 0
    var country: String = "US"
    var tipPercentage: Double = 0
    var tipAmmout: Double = 0
    var total: Double = 0
    
    func getTotal() {
        total = (billAmount) + tipAmmout
    }
    
    func clear() {
        billAmount = 0
        country = ""
        tipAmmout = 0
        total = 0
    }
    
    func getTipAmount() {
        tipAmmout = (tipPercentage * billAmount)
    }
    
    func getTipPercentage() {
        tipPercentage = countriesAndTips[country]!
    }
    
    
}

