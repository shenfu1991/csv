//
//  File.swift
//  
//
//  Created by xuanyuan on 2023/9/5.
//

import Foundation

extension Array where Element == Double {
    func rolling(window: Int) -> [[Double]] {
        var result: [[Double]] = []
        for i in 0..<(count - window + 1) {
            let subArray = Array(self[i..<i+window])
            result.append(subArray)
        }
        return result
    }
    
    var standardDeviation: Double? {
        guard count > 0 else { return nil }
        let avg = reduce(0, +) / Double(count)
        let sumOfSquaredAvgDiff = reduce(0, { $0 + pow($1 - avg, 2.0) })
        return sqrt(sumOfSquaredAvgDiff / Double(count))
    }
}






