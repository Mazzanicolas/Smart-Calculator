///Users/SP22/Documents/Smart-Calculator/SmartCalculator
//  calculator.swift
//  SmartCalculator
//
//  Created by SP22 on 27/6/18.
//  Copyright © 2018 UCU. All rights reserved.
//

import Foundation

class Calculator {
    
    
    func evaluate(operation: Array<String>) -> Int {
        var result = 0
        for element in operation {
            result += Int(element)!
        }
        return result
    }
    
    func addition(rhs: Int, lhs: Int) -> Int {
        return rhs+lhs
    }
    
    func substraction(rhs: Int, lhs: Int) -> Int {
        return rhs-lhs
    }
    
    func multiplication(rhs: Int, lhs: Int) -> Int {
        return rhs*lhs
    }
    
    func division(rhs: Int, lhs: Int) -> Int {
        if lhs == 0 {return 0}
        return rhs/lhs
    }
}
