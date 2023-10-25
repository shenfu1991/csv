//
//  File.swift
//
//
//  Created by xuanyuan on 2023/6/3.
//
import Foundation
import SwiftCSV
import CoreML

var csvUrl: URL!

var pathName = ""
var itName = ""
var sbName = ""
var pathIdx = 0
var sbIdx = 0
var gModel: MLModel!

//let sbArr = ["IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]

//let sbArr = ["CYBERUSDT", "SEIUSDT", "UNFIUSDT", "API3USDT", "STXUSDT", "PENDLEUSDT", "ARKMUSDT", "ZENUSDT", "MAVUSDT", "WLDUSDT", "SKLUSDT", "BCHUSDT", "GTCUSDT", "YGGUSDT", "COMBOUSDT", "OGNUSDT","AMBUSDT","LITUSDT","ARPAUSDT","SSVUSDT"]
//let sbArr = [ "MAVUSDT", "WLDUSDT", "SKLUSDT", "BCHUSDT", "GTCUSDT", "YGGUSDT", "COMBOUSDT", "OGNUSDT","AMBUSDT","LITUSDT","ARPAUSDT","SSVUSDT"]

//let sbArr = ["TOMOUSDT","ALPHAUSDT","NKNUSDT","RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
//let sbArr = ["RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
let sbArr = ["IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
//let sbArr = ["IMXUSDT","RDNTUSDT","ALPHAUSDT"]
let itArr = ["5m","30m"]
let pathArr = ["5m","30m"]
//let itArr = ["15m","30m","1h"]
//let pathArr = ["15m","30m","1h"]

let modelArr = ["rt4"]
var modelIdx = 0
var modelName = ""
let rootPath = "6-30-8-3"
//let rootPath = "all"
let csvHeader = "cci,duck,di,adx,result\n"

class CoreViewController {
    
    func configModels() {
        loopTask()
        
//        testF()
        
    }
    
    func testF() {
        let home = "/Users/xuanyuan/Documents/csv/"
        let url = home + "12.csv"
        csvUrl = URL(fileURLWithPath:url)
        try? csvHeader.write(to: csvUrl, atomically: true, encoding: .utf8)
        
        
        for _ in 0...10000 {
            
            let rsi = Double.random(in: 0...100)
            let so = Double.random(in: -100...100)
            let mfi = Double.random(in: 0...100)
            let cci = Double.random(in: 100...200)
            var res = "none"
            if rsi >= 70 && mfi <= 30 {
                res = "long"
            }else if rsi <= 30 && mfi >= 70 {
                res = "short"
            }
            let newRow = "\(rsi.fmt(x: 3)),\(so.fmt(x: 3)),\(mfi.fmt(x: 3)),\(cci.fmt(x: 3)),\(res)\n"
            addContent(text: newRow)
        }
        
        exit(0)
        
    }
    
    func loopTask() {
        
        pathName = pathArr[pathIdx]
        sbName = sbArr[sbIdx]
        itName = itArr[pathIdx]

        initFile()
        readCsvFiles()
    }
    
    func nextFile() {
        sbIdx += 1
        if sbIdx >= sbArr.count {
            sbIdx = 0
            pathIdx += 1
            if pathIdx >= pathArr.count {
                debugPrint("all finished")
                exit(0)
            }
        }
        loopTask()
    }
    
    func initFile() {
        
        let home = "/Users/xuanyuan/Documents/csv/"
        let url = home + sbName + "_" + itName + "_\(pathName).csv"
        csvUrl = URL(fileURLWithPath:url)
//        try? "iRank,minRate,maxRate,volatility,sharp,signal,minR,maxR,result\n".write(to: csvUrl, atomically: true, encoding: .utf8)
        try? csvHeader.write(to: csvUrl, atomically: true, encoding: .utf8)
    }
    
    func readCsvFiles() {
        
        do {

            let path = "/Users/xuanyuan/Downloads/\(rootPath)/\(pathName)/\(sbName)_\(itName).csv"
            
            NSLog("path=\(path)")

            let csvFileUrl = URL(fileURLWithPath: path)

            let csvFile = try CSV<Named>(url: csvFileUrl)
            
            // 获取所有行
            let rows = csvFile.rows
            
//            "timestamp,current,open,high,low,rate,volume,volatility,sharp,signal\n"/
            let limit = 1800
            let backLimit = getMins()*30*40
            var lc = 0
            var sc = 0
            var nc = 0
            for (idx,_) in rows.enumerated() {
                // 使用列名来访问数据
                
                if idx >= (limit+backLimit)-1 {
                    let midIdx = idx-limit+1
                    let midRow = rows[midIdx]
                    let fcurrent = midRow["current"]?.doubleValue() ?? 0
//                    let volatility = midRow["volatility"]?.doubleValue() ?? 0
//                    let sharp = midRow["sharp"]?.doubleValue() ?? 0
//                    let signal = midRow["signal"]?.doubleValue() ?? 0
                    if fcurrent == 0 {
                        continue
                    }
                    
                    autoreleasepool {

                        let foreArr = rows[(midIdx)...idx]
                        let foreCurrents = foreArr.map { dic in
                            (dic["current"] ?? "").doubleValue()
                        }
                        
                        let backIdx = midIdx - backLimit + 1
                        let backArr = rows[(backIdx)...midIdx]
                        let backPrices = backArr.map { dic in
                            (dic["current"] ?? "").doubleValue()
                        }
                        let vols = backArr.map { dic in
                            (dic["volume"] ?? "").doubleValue()
                        }
 
                        let tag = shenfu(current: fcurrent, volumes: vols, backPrices: backPrices, forePrices: foreCurrents)
                        
                        let newRow = "\(tag.0.fmt(x: 3)),\(tag.1.fmt(x: 3)),\(tag.2.fmt(x: 3)),\(tag.3.fmt(x: 3)),\(tag.4)\n"
//
                        addContent(text: newRow)

                        let flg = tag.4
                        
                        if flg == "long" {
                            lc += 1
                        }else if flg == "short" {
                            sc += 1
                        }else {
                           nc += 1
                        }
                    }
                }
            }
            debugPrint("finished")
            debugPrint(" \(sbName) \(lc),\(sc),\(nc)")
            debugPrint("next file...")
            nextFile()
        } catch let error {
            print("Error reading CSV file: \(error)")
            nextFile()
        }
    }
    
    func addContent(text: String) {
        do {
            let fileHandle = try FileHandle(forWritingTo: csvUrl)
            
            // 将文件指针移动到文件末尾
            fileHandle.seekToEndOfFile()
            
            if let data = text.data(using: .utf8) {
                fileHandle.write(data)
            }
            
            fileHandle.closeFile()
        }catch {
            
        }
    }
    
    func getMins() ->Int {
        var mins = 3
        if itName == "5m" {
            mins = 5
        }else if itName == "15m" {
            mins = 15
        }else if itName == "30m" {
            mins = 30
        }else if itName == "1h" {
            mins = 60
        }else if itName == "4h" {
            mins = 240
        }
        return mins
    }

    func assArr4mins(arr: [Double],leng: Int,high: Bool=false,low:Bool=false,close:Bool=false) ->[Double] {
        
       let mins = getMins()
        let d = arr
        
        let cc = arr.count-1
        if cc < 13 {
            return []
        }
        var finalArr: [Double] = []
        for i in 0...leng-1 {
            let count = 30*mins
            let from = cc-count*(i+1)+1
            let to = cc-count*i
//            debugPrint("i=\(i),cc=\(arr.count)")
            let tmp = d[from...to]
            if high {
                let h = tmp.max() ?? 0
                finalArr.append(h)
            }else if low {
                let l = tmp.min() ?? 0
                finalArr.append(l)
            }else if close {
                let l = tmp.last ?? 0
                finalArr.append(l)
            }else{
                let avg = getAvg(Array(tmp))
                finalArr.append(avg)
            }
        }
        return finalArr
    }

    func shenfu(current: Double,volumes: [Double],backPrices: [Double],forePrices: [Double]) ->(Double,Double,Double,Double,String) {
        let r = 0.0125*2
        
        let minX = forePrices.min() ?? 0
        let maxX = forePrices.max() ?? 0
        let po = 40
//        let arr14 = assArr4mins(arr: backPrices, leng: 14)
        let highs = assArr4mins(arr: backPrices, leng: po,high: true)
        let lows = assArr4mins(arr: backPrices, leng: po,low: true)
        let closes = assArr4mins(arr: backPrices, leng: po,close: true)

     
        let cci = calculateCCI(highs: highs, lows: lows, closes: closes).last ?? 0
        let duckData = calculateDonchianChannel(prices: closes, window: 14)
        var duck: Double = 0
        let upperBand = duckData.upperBand.last ?? 0
        let lowerBand = duckData.lowerBand.last ?? 0
        if current > upperBand {
            duck = 1
        }else if current < lowerBand  {
            duck = -1
        }
        let dmi = calculateDMI(highs: highs, lows: lows, closes: closes, period: 14)
        let dip = dmi.0.last ?? 0
        let dim = dmi.1.last ?? 0
        let di: Double = dip >= dim ? 1 : -1
        let adx = dmi.2.last ?? 0

//        "cci,duck,di,adx,
        
        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return (cci,duck,di,adx,"short")
            }
            return (cci,duck,di,adx,"none")
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return (cci,duck,di,adx,"long")
                }
                 return (cci,duck,di,adx,"none")
            }else{
                if (current - minX)/minX >= r {
                    return (cci,duck,di,adx,"short")
                }
                return (cci,duck,di,adx,"none")
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return (cci,duck,di,adx,"long")
            }
            return (cci,duck,di,adx,"none")
        }
       
        return (0,0,0,0,"none")
    }

    
}

func getAvg(_ arr: [Double]) ->Double {
    let sum = arr.reduce(0, +)
    return sum / Double(arr.count)
}
