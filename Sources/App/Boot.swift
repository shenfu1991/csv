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

//let sbArr = ["BTCUSDT","ETHUSDT","TOMOUSDT","ALPHAUSDT","NKNUSDT","RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
let sbArr = ["TOMOUSDT","ALPHAUSDT","RSRUSDT","GRTUSDT","IMXUSDT","MAGICUSDT","RDNTUSDT"]
let itArr = ["3m","5m","15m","30m","1h","4h"]
let pathArr = ["3m","5m","15m","30m","1h","4h"]

let modelArr = ["rt4"]
var modelIdx = 0
var modelName = ""
let rootPath = "7-12"

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
        try? "iRank,minRate,maxRate,volatility,sharp,signal,result\n".write(to: csvUrl, atomically: true, encoding: .utf8)
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
            var lc = 0
            var sc = 0
            var lnc = 0
            var snc = 0
            for (idx,_) in rows.enumerated() {
                // 使用列名来访问数据
                
                if idx >= limit*2 {
                    let midIdx = idx-limit
                    let midRow = rows[midIdx]
                    let fcurrent = midRow["current"]?.doubleValue() ?? 0
                    if fcurrent == 0 {
                        continue
                    }
                    
                    autoreleasepool {
                        let fvolatility = midRow["volatility"]?.doubleValue() ?? 0
                        let fsharp = midRow["sharp"]?.doubleValue() ?? 0
                        let fsignal = midRow["signal"]?.doubleValue() ?? 0
                        
                        let foreArr = rows[(midIdx+2)...idx]
                        let foreCurrents = foreArr.map { dic in
                            (dic["current"] ?? "").doubleValue()
                        }
                        
                        let backIdx = idx-(2*limit)
                        let backArr = rows[(backIdx+1)...midIdx-1]

                        let backPrices = backArr.map { dic in
                            (dic["current"] ?? "").doubleValue()
                        }
                        
//                        let tag = getTag(current:fcurrent, values: foreCurrents,prePrices: backPrices)
                        let tag = getTag2(current:fcurrent,prePrices: backPrices)
                        
//                        "minRate,maxRate,volatility,sharp,signal,result\n"
                        let newRow = "\(tag.3.fmt(x: 2)),\(tag.1.fmt()),\(tag.2.fmt()),\(fvolatility.fmt()),\(fsharp.fmt()),\(fsignal.fmt()),\(tag.0)\n"
                        
                        if tag.0 != "" {
                            addContent(text: newRow)
                        }
                        if tag.0 == "long" {
                            lc += 1
                        }else if tag.0 == "short" {
                            sc += 1
                        }else if tag.0 == "LN" {
                            lnc += 1
                        }else if tag.0 == "SN" {
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
        let r = current > 100 ? 0.0125 : 0.0125*2
        
        let minX = values.min() ?? 0
        let maxX = values.max() ?? 0
        let sub1 = fabs(maxX - current)
        let sub2 = fabs(minX - current)
        
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
        let r = current > 100 ? 0.0125 : 0.0125*2

        let minX = prePrices.min() ?? 0
        let maxX = prePrices.max() ?? 0
        
        let sub1 = fabs(maxX - current)
        let sub2 = fabs(minX - current)
        
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
    
    
}
