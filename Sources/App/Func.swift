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

// 计算唐奇安通道
func calculateDonchianChannel(prices: [Double], window: Int) -> (upperBand: [Double], lowerBand: [Double]) {
    var upperBand: [Double] = []
    var lowerBand: [Double] = []
    
    // 确保数据量大于时间窗口
    guard prices.count >= window else {
        return (upperBand, lowerBand)
    }
    
    for i in 0..<prices.count {
        if i < window - 1 {
            // 不足窗口大小的数据，无法计算唐奇安通道
            upperBand.append(0)
            lowerBand.append(0)
            continue
        }
        
        let slice = Array(prices[(i - window + 1)...i])
        if let maxPrice = slice.max(), let minPrice = slice.min() {
            upperBand.append(maxPrice)
            lowerBand.append(minPrice)
        } else {
            upperBand.append(0)
            lowerBand.append(0)
        }
    }
    
    return (upperBand, lowerBand)
}

import Foundation

func calculateDMI(highs: [Double], lows: [Double], closes: [Double], period: Int) -> ([Double], [Double], [Double]) {
    var plusDMs: [Double] = []
    var minusDMs: [Double] = []
    var trueRanges: [Double] = []
    var plusDIs: [Double] = []
    var minusDIs: [Double] = []
    var adxs: [Double] = []

    for i in 1..<highs.count {
        let deltaHigh = highs[i] - highs[i - 1]
        let deltaLow = lows[i - 1] - lows[i]
        
        let plusDM = max(deltaHigh, 0)
        let minusDM = max(deltaLow, 0)
        
        plusDMs.append((deltaHigh > deltaLow && deltaHigh > 0) ? deltaHigh : 0)
        minusDMs.append((deltaLow > deltaHigh && deltaLow > 0) ? deltaLow : 0)
        
        let trueRange = max(highs[i] - lows[i], abs(highs[i] - closes[i - 1]), abs(lows[i] - closes[i - 1]))
        trueRanges.append(trueRange)
    }

    for i in (period - 1)..<(highs.count - 1) {
        let plusDMPeriod = plusDMs[i - period + 1...i].reduce(0, +)
        let minusDMPeriod = minusDMs[i - period + 1...i].reduce(0, +)
        let trueRangePeriod = trueRanges[i - period + 1...i].reduce(0, +)

        let plusDI = 100 * (plusDMPeriod / trueRangePeriod)
        let minusDI = 100 * (minusDMPeriod / trueRangePeriod)

        plusDIs.append(plusDI)
        minusDIs.append(minusDI)

        let dx = 100 * abs(plusDI - minusDI) / (plusDI + minusDI)
        if i >= (2 * period) - 2 {
            let adx = Array(adxs.suffix(period - 1)).compactMap { $0 }.reduce(dx, +) / Double(period)
            adxs.append(adx)
        } else {
            adxs.append(-100)
        }
    }

    return (plusDIs, minusDIs, adxs)
}

