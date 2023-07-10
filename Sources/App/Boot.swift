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

let sbArr = ["BTCUSDT","ETHUSDT","TOMOUSDT","ALPHAUSDT","NKNUSDT","RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
//let pathArr = ["3mv3","5mv3","15mv3","30mv3","1hv3","4hv3"]
let itArr = ["3m","5m","15m","30m","1h","4h"]
let pathArr = ["3m","5m","15m","30m","1h","4h"]
//let pathArr = ["3m","5m","15m","30m","3mv2","5mv2","15mv2","30mv2","3mv3","5mv3","15mv3","30mv3","1hv3","4hv3"]
//let itArr = ["3m","5m","15m","30m","3m","5m","15m","30m","3m","5m","15m","30m","1h","4h"]

//let pathArr = ["15m"]
//let itArr = ["15m"]
//let modelArr = ["15v3","15v4","15v5","15v6","15v7","15v8","15v9","15v10"]
let modelArr = ["rt4"]
var modelIdx = 0
var modelName = ""

class CoreViewController {
    
    func configModels() {
        loopTask()
        
//        loopTest()
    }
    
    func loopTest() {
        sbName = sbArr[sbIdx]
        modelName = modelArr[modelIdx]
        loadModel()
        testModel()
    }
    
    func nextModel() {
        sbIdx += 1
        if sbIdx >= sbArr.count {
            sbIdx = 0
            modelIdx += 1
            if modelIdx >= modelArr.count {
                debugPrint("all finished")
                exit(0)
            }
        }
        loopTest()
    }
    
    func loadModel() {
        var file = #file.components(separatedBy: "App").first ?? ""
        file += "/Resources/\(modelName).mlmodel"
        let modelUrl = URL(fileURLWithPath: file)
        if let compiledUrl = try? MLModel.compileModel(at: modelUrl) {
            let model = try? MLModel(contentsOf: compiledUrl)
            gModel = model
        }
    }
    
    func testModel() {
        
        do {

            let path = "/Users/xuanyuan/Documents/validation/\(sbName)_15m_15m.csv"

            let csvFileUrl = URL(fileURLWithPath: path)

            let csvFile = try CSV<Named>(url: csvFileUrl)
            
            // 获取所有行
            let rows = csvFile.rows
            
            if rows.isEmpty {
                debugPrint("无数据，next...")
                nextModel()
                return
            }
            
//            "timestamp,current,open,high,low,rate,volume,volatility,sharp,signal\n"/
            var lc = 0
            var sc = 0
            var lnc = 0
            var snc = 0
            var blc = 0
            var bsc = 0
            var blnc = 0
            var bsnc = 0
            
            for (idx,_) in rows.enumerated() {
                // 使用列名来访问数据
                autoreleasepool {

                    let firstRow = rows[idx]
                    let fcurrent = firstRow["current"]?.doubleValue() ?? 0
                    let favg = firstRow["avg"]?.doubleValue() ?? 0
                    let fopen = firstRow["open"]?.doubleValue() ?? 0
                    let fhigh = firstRow["high"]?.doubleValue() ?? 0
                    let flow = firstRow["low"]?.doubleValue() ?? 0
                    let frate = firstRow["rate"]?.doubleValue() ?? 0
                    let fvolume = firstRow["volume"]?.doubleValue() ?? 0
                    let fvolatility = firstRow["volatility"]?.doubleValue() ?? 0
                    let fsharp = firstRow["sharp"]?.doubleValue() ?? 0
                    let fsignal = firstRow["signal"]?.doubleValue() ?? 0
                    let fResult = firstRow["result"]

                    let dict = [
                        "current": fcurrent.fmt(),
                        "avg": favg.fmt(),
                        "open": fopen.fmt(),
                        "high": fhigh.fmt(),
                        "low": flow.fmt(),
                        "rate": frate.fmt(),
                        "volume": fvolume.fmt(x: 2),
                        "volatility": fvolatility.fmt(),
                        "sharp": fsharp.fmt(),
                        "signal": fsignal.fmt()
                    ]
                    
                    let res = model4Res(dict: dict)
                    
                    if fResult == "long" {
                        lc += 1
                    }else if fResult == "short" {
                        sc += 1
                    }else if fResult == "LN" {
                        lnc += 1
                    }else if fResult == "SN" {
                        snc += 1
                    }
                    
                    if res == fResult {
                        
                        if fResult == "long" {
                            blc += 1
                        }else if fResult == "short" {
                            bsc += 1
                        }else if fResult == "LN" {
                            blnc += 1
                        }else if fResult == "SN" {
                            bsnc += 1
                        }
                        
                    }
                      
                    }
                }
            
            debugPrint("\(modelName) \(sbName)")
            debugPrint("long acc: \((Double(blc)/Double(lc)).str2F()),all count: \(lc)")
            debugPrint("short acc: \((Double(bsc)/Double(sc)).str2F()),all count: \(sc)")
            debugPrint("LN acc: \((Double(blnc)/Double(lnc)).str2F()),all count: \(lnc)")
            debugPrint("SN acc: \((Double(bsnc)/Double(snc)).str2F()),all count: \(snc)")
            debugPrint("all \(lc+sc+lnc+snc)")
           
            nextModel()
         
        } catch let error {
           
        }
                
    }
    
    func model4Res(dict: [String: Any]) ->String{
        let pro = try? MLDictionaryFeatureProvider(dictionary: dict)
        if let res = try? gModel.prediction(from: pro!) {
            if let num = res.featureValue(for: "result") {
                let str = (num).stringValue
                return str
            }
        }else{
            debugPrint("模型加载失败: \(dict)")
            return ""
        }
        return ""
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
//        let url = home + "\(Int.random(in: 99999...1000000000)).csv"
        let url = home + sbName + "_" + itName + "_\(pathName).csv"
        csvUrl = URL(fileURLWithPath:url)
        try? "current,avg,open,high,low,rate,volume,volatility,sharp,signal,result\n".write(to: csvUrl, atomically: true, encoding: .utf8)
    }
    
    func readCsvFiles() {
        
        do {

            let path = "/Users/xuanyuan/Downloads/io/\(pathName)/\(sbName)_\(itName).csv"

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
                
                if idx >= limit {
                    let firstRow = rows[idx-(limit-1)]
                    let fcurrent = firstRow["current"]?.doubleValue() ?? 0
                    if fcurrent == 0 {
                        continue
                    }
                    
                    autoreleasepool {
                        let arr = rows[idx-(limit-1)...idx]
                        let fopen = firstRow["open"]?.doubleValue() ?? 0
                        let fhigh = firstRow["high"]?.doubleValue() ?? 0
                        let flow = firstRow["low"]?.doubleValue() ?? 0
                        let frate = firstRow["rate"]?.doubleValue() ?? 0
                        let fvolume = firstRow["volume"]?.doubleValue() ?? 0
                        let fvolatility = firstRow["volatility"]?.doubleValue() ?? 0
                        let fsharp = firstRow["sharp"]?.doubleValue() ?? 0
                        let fsignal = firstRow["signal"]?.doubleValue() ?? 0
                        
                        let foreCurrents = arr.map { dic in
                            (dic["current"] ?? "").doubleValue()
                        }
                        
                        let avg = (fopen + fhigh + flow + fcurrent)/4.0
                        let tag = getTag(current:fcurrent, values: foreCurrents)
                        
                        //                    open,high,low,rate,volume,volatility,sharp,signal,result\n
                        let newRow = "\(fcurrent.fmt()),\(avg.fmt()),\(fopen.fmt()),\(fhigh.fmt()),\(flow.fmt()),\(frate.fmt()),\(fvolume.fmt()),\(fvolatility.fmt()),\(fsharp.fmt()),\(fsignal.fmt()),\(tag)\n"
                        
                        if tag != "" {
                            addContent(text: newRow)
                        }
                        if tag == "long" {
                            lc += 1
                        }else if tag == "short" {
                            sc += 1
                        }else if tag == "LN" {
                            lnc += 1
                        }else if tag == "SN" {
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
    
    func getTag(current: Double,values: [Double]) ->String {
        let r = current > 100 ? 0.0125 : 0.0125*2
        var lc = 0
        var sc = 0
        var lnc = 0
        var snc = 0
        
        let minX = values.min() ?? 0
        let maxX = values.max() ?? 0
        let sub1 = fabs(maxX - current)
        let sub2 = fabs(minX - current)
        
        if current >= maxX && current >= minX  {
            if (current - minX)/minX >= r {
                return "short"
            }
            return "SN"
        }else if current <= maxX && current >= minX  {
            if sub1 > sub2 {
                if (maxX - current)/current >= r {
                    return "long"
                }
                return "LN"
            }else{
                if (current - minX)/minX >= r {
                    return "short"
                }
                return "SN"
            }
        }else if current <= maxX && current <= minX  {
            if (maxX - current)/current >= r {
                return "long"
            }
            return "LN"
        }
        
        
//        for v in values {
//            if v > current {
//                if (v - current)/current >= r {
//                    lc += 1
//                }else{
//                    lnc += 1
//                }
//            }else{
//                if (current - v)/v >= r {
//                    sc += 1
//                }else{
//                    snc += 1
//                }
//            }
//        }
//
//        if lc > 0 || sc > 0 {
//            if lc > sc {
//                return "long"
//            }
//            return "short"
//        }else {
//            if lnc > snc {
//                return "LN"
//            }
//            return "SN"
//        }
        
        return ""
    }
    
    
}
