//
//  exDouble.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 30/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import Foundation

extension Double {
    
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
