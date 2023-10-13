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

//let sbArr = ["TOMOUSDT","ALPHAUSDT","NKNUSDT","RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
let sbArr = ["LQTYUSDT"]
//let sbArr = ["TOMOUSDT","ALPHAUSDT","RSRUSDT","GRTUSDT","IMXUSDT","MAGICUSDT","RDNTUSDT"]
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
let csvHeader = "rank,upDownMa23,volatility,sharp,signal,result\n"

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
            let backLimit = 900
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
                    let volatility = midRow["volatility"]?.doubleValue() ?? 0
                    let sharp = midRow["sharp"]?.doubleValue() ?? 0
                    let signal = midRow["signal"]?.doubleValue() ?? 0
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
 
                        let tag = MengZhiHong(current: fcurrent, backPrices: backPrices, forePrices: foreCurrents)
                        let newRow = "\(tag.0.fmt(x: 3)),\(tag.1),\(volatility.fmt(x: 3)),\(sharp.fmt(x: 3)),\(signal.fmt(x: 3)),\(tag.2)\n"
//
                        addContent(text: newRow)

                        let flg = tag.2
                        
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
    
    func getTag(current: Double,values: [Double],prePrices: [Double]) ->(String,Double,Double,Double) {
        let r = 0.0125*2
        
        let minX = values.min() ?? 0
        let maxX = values.max() ?? 0
 
        
        let minX2 = prePrices.min() ?? 0
        let maxX2 = prePrices.max() ?? 0
        
        var iR: Double = -1
        var fu = prePrices
        fu.append(current)
        fu.sort()
        
        if let idx = fu.firstIndex(of: current) {
            iR = Double(idx)/Double(fu.count)
        }
        
        let minRate = minX2/current
        let maxRate = maxX2/current
        
        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return ("long",minRate,maxRate,iR)
            }
            return ("LN",minRate,maxRate,iR)
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return ("long",minRate,maxRate,iR)
                }
                return ("LN",minRate,maxRate,iR)
            }else{
                if (current - minX)/minX >= r {
                    return ("short",minRate,maxRate,iR)
                }
                return ("SN",minRate,maxRate,iR)
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return ("short",minRate,maxRate,iR)
            }
            return ("SN",minRate,maxRate,iR)
        }
        
        return ("",0,0,-1)
    }
    
    func getTag2(current: Double,prePrices: [Double]) ->(String,Double,Double,Double) {
        let r = 0.0125*2

        let minX = prePrices.min() ?? 0
        let maxX = prePrices.max() ?? 0
        
        var iR: Double = -1
        var fu = prePrices
        fu.append(current)
        fu.sort()
        
        if let idx = fu.firstIndex(of: current) {
            iR = Double(idx)/Double(fu.count)
        }
        
        let minRate = minX/current
        let maxRate = maxX/current
        
        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return ("long",minRate,maxRate,iR)
            }
            return ("LN",minRate,maxRate,iR)
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return ("long",minRate,maxRate,iR)
                }
                return ("LN",minRate,maxRate,iR)
            }else{
                if (current - minX)/minX >= r {
                    return ("short",minRate,maxRate,iR)
                }
                return ("SN",minRate,maxRate,iR)
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return ("short",minRate,maxRate,iR)
            }
            return ("SN",minRate,maxRate,iR)
        }
        
        return ("",0,0,-1)
    }
    
    func getTag3(current: Double,backPrices: [Double],forePrices: [Double]) ->(String,Double,Double,Double,Double,Double) {
        let r = 0.0125*2

        let minX = backPrices.min() ?? 0
        let maxX = backPrices.max() ?? 0
        
        let sub1 = fabs(maxX - current)
        let sub2 = fabs(minX - current)
        
        var iR: Double = -1
        var fu = backPrices
        fu.append(current)
        fu.sort()
        
        if let idx = fu.firstIndex(of: current) {
            iR = Double(idx)/Double(fu.count)
        }
        
        let minRate = minX/current
        let maxRate = maxX/current
        
        let minR = (current - minX)/minX
        let maxR = (current - maxX)/maxX

        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                let tag = featureStatus(current: current, forePrices: forePrices)
                if tag == "long" {
                    return ("long",minRate,maxRate,iR,minR,maxR)
                }
                return ("LN",minRate,maxRate,iR,minR,maxR)
            }
            return ("LN",minRate,maxRate,iR,minR,maxR)
        }else if current <= maxX && current >= minX  {
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    let tag = featureStatus(current: current, forePrices: forePrices)
                    if tag == "long" {
                        return ("long",minRate,maxRate,iR,minR,maxR)
                    }
                    return ("LN",minRate,maxRate,iR,minR,maxR)
                }
                return ("LN",minRate,maxRate,iR,minR,maxR)
            }else{
                if (current - minX)/minX >= r {
                    let tag = featureStatus(current: current, forePrices: forePrices)
                    if tag == "short" {
                        return ("short",minRate,maxRate,iR,minR,maxR)
                    }
                    return ("SN",minRate,maxRate,iR,minR,maxR)
                }
                return ("SN",minRate,maxRate,iR,minR,maxR)
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                let tag = featureStatus(current: current, forePrices: forePrices)
                if tag == "short" {
                    return ("short",minRate,maxRate,iR,minR,maxR)
                }
                return ("SN",minRate,maxRate,iR,minR,maxR)
            }
            return ("SN",minRate,maxRate,iR,minR,maxR)
        }
        
        return ("",0,0,-1,0,0)
    }
    
    func featureStatus(current: Double,forePrices: [Double]) ->String {
        let r = 0.0125*2

        let minX = forePrices.min() ?? 0
        let maxX = forePrices.max() ?? 0
        
        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return ("long")
            }
            return ("LN")
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return ("long")
                }
                return ("LN")
            }else{
                if (current - minX)/minX >= r {
                    return ("short")
                }
                return ("SN")
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return ("short")
            }
            return ("SN")
        }
        
        return ""
    }
    
    
//    "rank,minR,maxR,minDiffR,maxDiffR,topRank,result\n
    
    func featureStatus6(current: Double,backPrices: [Double],forePrices: [Double]) ->(Double,Double,Double,Double,Double,Double,String) {
        let r = 0.0125*2
        
        let minX = forePrices.min() ?? 0
        let maxX = forePrices.max() ?? 0
        
        let cc = backPrices.count-1
        
        var rank: Double = -1
        var fu = backPrices
        fu.append(current)
        fu.sort()
        if let idx = fu.firstIndex(of: current) {
            rank = Double(idx)/Double(fu.count)
        }
        
        let backMin = backPrices.min() ?? 0
        let backMax = backPrices.max() ?? 0
        let minR = backMin/current
        let maxR = backMax/current
        
        let minDiffR = (backMin-current)/current
        let maxDiffR = (backMax-current)/current
        
        let topIdx = Int(Double(cc)*0.25)
        let topArr = Array(backPrices[cc-topIdx...cc])
        
        var topRank: Double = -1
        var fu2 = topArr
        fu2.append(current)
        fu2.sort()
        if let idx = fu2.firstIndex(of: current) {
            topRank = Double(idx)/Double(fu2.count)
        }

        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"long")
            }
            return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"LN")
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"long")
                }
                return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"LN")
            }else{
                if (current - minX)/minX >= r {
                    return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"short")
                }
                return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"SN")
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
               return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"short")
            }
            return (rank,minR,maxR,minDiffR,maxDiffR,topRank,"SN")
        }
       
        return (0,0,0,0,0,0,"LN")
    }
    
    func MengZhiHong(current: Double,backPrices: [Double],forePrices: [Double]) ->(Double,String,String) {
        let r = 0.0125*2
        
        let minX = forePrices.min() ?? 0
        let maxX = forePrices.max() ?? 0
        
        let cc = backPrices.count-1
        
        var rank: Double = -1
        var fu = backPrices
        fu.append(current)
        fu.sort()
        if let idx = fu.firstIndex(of: current) {
            rank = Double(idx)/Double(fu.count)
        }
        
        let ma25 = getAvg(Array(backPrices[cc-450...cc]))
        let upDownMa25 = current >= ma25 ? "up" : "down"

        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return (rank,upDownMa25,"short")
            }
            return (rank,upDownMa25,"SN")
        }else if current <= maxX && current >= minX  {
            let sub1 = fabs(maxX - current)
            let sub2 = fabs(minX - current)
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return (rank,upDownMa25,"long")
                }
                 return (rank,upDownMa25,"LN")
            }else{
                if (current - minX)/minX >= r {
                    return (rank,upDownMa25,"short")
                }
                return (rank,upDownMa25,"SN")
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return (rank,upDownMa25,"long")
            }
            return (rank,upDownMa25,"LN")
        }
       
        return (0,"","LN")
    }


    
}

func getAvg(_ arr: [Double]) ->Double {
    let sum = arr.reduce(0, +)
    return sum / Double(arr.count)
}
