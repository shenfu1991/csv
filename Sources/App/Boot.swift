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

let sbArr = ["TOMOUSDT","ALPHAUSDT","NKNUSDT","RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
//let sbArr = ["LQTYUSDT"]
//let sbArr = ["ALPHAUSDT","RSRUSDT","GRTUSDT","IMXUSDT","MAGICUSDT","RDNTUSDT"]
//let sbArr = ["IMXUSDT","RDNTUSDT","ALPHAUSDT"]
let itArr = ["15m"]
let pathArr = ["15m"]
//let itArr = ["15m","30m","1h"]
//let pathArr = ["15m","30m","1h"]

let modelArr = ["rt4"]
var modelIdx = 0
var modelName = ""
let rootPath = "6-30-8-3"
//let rootPath = "all"
let csvHeader = "rsi,so,mfi,cci,result\n"

class CoreViewController {
    
    func configModels() {
        loopTask()
        
//        loopTest()
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
            let backLimit = 2100
            var lc = 0
            var sc = 0
            var lnc = 0
            var snc = 0
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
                        let highs = backArr.map { dic in
                            (dic["high"] ?? "").doubleValue()
                        }
                        let lows = backArr.map { dic in
                            (dic["low"] ?? "").doubleValue()
                        }
                        let vols = backArr.map { dic in
                            (dic["volume"] ?? "").doubleValue()
                        }
 
                        let tag = shenfu(current: fcurrent, highs: highs, lows: lows, closes: backPrices, volumes: vols, backPrices: backPrices, forePrices: foreCurrents)
                        
                        let newRow = "\(tag.0.fmt(x: 3)),\(tag.1.fmt(x: 3)),\(tag.2.fmt(x: 3)),\(tag.3.fmt(x: 3)),\(tag.4)\n"
//
                        addContent(text: newRow)

                        let flg = tag.4
                        
                        if flg == "long" {
                            lc += 1
                        }else if flg == "short" {
                            sc += 1
                        }else if flg == "LN" {
                            lnc += 1
                        }else if flg == "SN" {
                            snc += 1
                        }
                    }
                }
            }
            debugPrint("finished")
            debugPrint(" \(sbName) \(lc),\(lnc),\(sc),\(snc)")
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

    func assArr4mins(arr: [Double],leng: Int,mins: Int = 5) ->[Double] {
        let cc = arr.count-1
        var finalArr: [Double] = []
        for i in 0...leng-1 {
            let count = 30*mins
            let from = cc-count*(i+1)+1
            let to = cc-count*i
//            debugPrint("from = \(from),to=\(to)")
            let avg = getAvg(Array(arr[from...to]))
            finalArr.append(avg)
        }
        return finalArr
    }

    func shenfu(current: Double,highs: [Double],lows: [Double],closes: [Double],volumes: [Double],backPrices: [Double],forePrices: [Double]) ->(Double,Double,Double,Double,String) {
        let r = 0.0125*2
        
        let minX = forePrices.min() ?? 0
        let maxX = forePrices.max() ?? 0
        
        let arr14 = assArr4mins(arr: backPrices, leng: 14)
//        let arr12 = assArr4mins(arr: backPrices, leng: 12)
//        let arr9 = assArr4mins(arr: backPrices, leng: 9)
        
        let hs = assArr4mins(arr: highs, leng: 14)
        let ls = assArr4mins(arr: lows, leng: 14)
        let cs = assArr4mins(arr: closes, leng: 14)
        let vs = assArr4mins(arr: volumes, leng: 14)
        
        let hs9 = assArr4mins(arr: highs, leng: 9)
        let ls9 = assArr4mins(arr: lows, leng: 9)
        let cs9 = assArr4mins(arr: closes, leng: 9)

        let rsi = calculateRSI(values: arr14).last ?? 0
        let mfi = calculateMFI(highs: hs, lows: ls, closes: cs, volumes: vs).last ?? 0
        let cci = calculateCCI(highs: hs9, lows: ls9, closes: cs9).last ?? 0
        let so = calculateStochasticOscillator(highs: hs, lows: ls, closes: cs).last ?? 0
        
//        rsi,so,mfi,cci,
        
        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return (rsi,so,mfi,cci,"short")
            }
            return (rsi,so,mfi,cci,"SN")
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return (rsi,so,mfi,cci,"long")
                }
                 return (rsi,so,mfi,cci,"LN")
            }else{
                if (current - minX)/minX >= r {
                    return (rsi,so,mfi,cci,"short")
                }
                return (rsi,so,mfi,cci,"SN")
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return (rsi,so,mfi,cci,"long")
            }
            return (rsi,so,mfi,cci,"LN")
        }
       
        return (0,0,0,0,"LN")
    }

    
}

func getAvg(_ arr: [Double]) ->Double {
    let sum = arr.reduce(0, +)
    return sum / Double(arr.count)
}
