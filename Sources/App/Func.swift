//
//  File.swift
//  
//
//  Created by xuanyuan on 2023/10/18.
//

import Foundation

func calculateRSI(values: [Double], period: Int=12) -> [Double] {
    if values.count < period {
        return []
    }
    
    var gains = [Double]()
    var losses = [Double]()
    var rsis = [Double]()
    
    for i in 1..<values.count {
        let change = values[i] - values[i-1]
        
        if change > 0 {
            gains.append(change)
            losses.append(0)
        } else {
            gains.append(0)
            losses.append(abs(change))
        }
    }
    
    for i in period..<values.count {
        let gainAvg = gains[(i-period)..<i].reduce(0, +) / Double(period)
        let lossAvg = losses[(i-period)..<i].reduce(0, +) / Double(period)
        
        let rs = gainAvg / lossAvg
        let rsi = 100 - (100 / (1 + rs))
        
        rsis.append(rsi)
    }
    
    return rsis
}

func calculateStochasticOscillator(highs: [Double], lows: [Double], closes: [Double], period: Int=14) -> [Double] {
    if highs.count < period || lows.count < period || closes.count < period {
        return []
    }
    
    var stochastics = [Double]()
    
    for i in (period - 1)..<highs.count {
        let highMax = highs[(i-period+1)...i].max()!
        let lowMin = lows[(i-period+1)...i].min()!
        
        let close = closes[i]
        
        let stochastic = ((close - lowMin) / (highMax - lowMin)) * 100
        stochastics.append(stochastic)
    }
    
    return stochastics
}

func calculateMFI(highs: [Double], lows: [Double], closes: [Double], volumes: [Double], period: Int=14) -> [Double] {
    if highs.count < period || lows.count < period || closes.count < period || volumes.count < period {
        return []
    }

    var mfis = [Double]()

    for i in (period - 1)..<highs.count {
        let typicalPricePeriod = zip(zip(highs[(i-period+1)...i], lows[(i-period+1)...i]), closes[(i-period+1)...i]).map { ($0.0 + $0.1 + $1) / 3 }
        let moneyFlows = zip(typicalPricePeriod, Array(volumes[(i-period+1)...i])).map { $0 * $1 }

        let positiveFlow = zip(moneyFlows.dropFirst(), moneyFlows).filter { $1 > $0 }.map { $1 }.reduce(0, +)
        let negativeFlow = zip(moneyFlows.dropFirst(), moneyFlows).filter { $1 < $0 }.map { $1 }.reduce(0, +)

        let moneyRatio = positiveFlow / negativeFlow
        let mfi = 100 - (100 / (1 + moneyRatio))

        mfis.append(mfi)
    }

    return mfis
}



func calculateCCI(highs: [Double], lows: [Double], closes: [Double], period: Int=9) -> [Double] {
    if highs.count < period || lows.count < period || closes.count < period {
        return []
    }

    var ccis = [Double]()

    for i in (period - 1)..<highs.count {
        let typicalPricePeriod = zip(zip(highs[(i-period+1)...i], lows[(i-period+1)...i]), closes[(i-period+1)...i]).map { ($0.0 + $0.1 + $1) / 3 }
        let sma = typicalPricePeriod.reduce(0, +) / Double(period)

        let meanDeviation = typicalPricePeriod.map { abs($0 - sma) }.reduce(0, +) / Double(period)

        let cci = (typicalPricePeriod.last! - sma) / (0.015 * meanDeviation)
        ccis.append(cci)
    }

    return ccis
}


