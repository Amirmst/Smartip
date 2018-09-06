//
//  TipDataModel.swift
//  Auto Layout Calculator
//
//  Created by amir reza mostafavi on 1/3/18.
//  Copyright © 2018 Amir Mostafavi. All rights reserved.
//

import UIKit

class TipDataModel {
    let countriesAndTips: [String : [Double]] = ["US" : [0.15, 0.17, 0.20], "FR" : [0.05, 0.07, 0.1], "SE" : [0, 0, 0]]
    var alert = false
    var billAmount: Double = 0
    var country: String = ""
    var tipPercentage: Double = 0
    var tipAmmout: Double = 0
    var total: Double = 0
    
    init(currentCountry: String, enteredBillAmount: Double) {
        country = currentCountry
        billAmount = enteredBillAmount
    }
    
    func getTotal() {
        total = (billAmount) + tipAmmout
    }
    
    func clear() {
        billAmount = 0
        country = ""
        tipAmmout = 0
        total = 0
        alert = false
    }
    
    func getTipAmount() {
        tipAmmout = (tipPercentage * billAmount)
    }
    
    func getTipPercentage(quality: Int) {
        let goodTip = countriesAndTips[country]![2]
        let medTip = countriesAndTips[country]![1]
        let badTip = countriesAndTips[country]![0]
        tipPercentage = countriesAndTips[country]![quality]
        if goodTip == 0 && medTip == 0 && badTip == 0 {
            alert = true
        }
    }
    
    
}

