//
//  File.swift
//
//
//  Created by xuanyuan on 2023/6/3.
//
import Foundation
import SwiftCSV

var csvUrl: URL!

var pathName = ""
var itName = ""
var sbName = ""
var pathIdx = 0
var sbIdx = 0

let sbArr = ["BTCUSDT","ETHUSDT","TOMOUSDT","ALPHAUSDT","NKNUSDT","RSRUSDT","GRTUSDT","HIGHUSDT","IMXUSDT","LPTUSDT","LQTYUSDT","MAGICUSDT","RDNTUSDT","WOOUSDT"]
//let pathArr = ["3mv3","5mv3","15mv3","30mv3","1hv3","4hv3"]
//let itArr = ["3m","5m","15m","30m","1h","4h"]
let pathArr = ["3m","5m","15m","30m","3mv2","5mv2","15mv2","30mv2","3mv3","5mv3","15mv3","30mv3","1hv3","4hv3"]
let itArr = ["3m","5m","15m","30m","3m","5m","15m","30m","3m","5m","15m","30m","1h","4h"]


class CoreViewController {
    
    func configModels() {
        loopTask()
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

            let path = "/Users/xuanyuan/Downloads/all/\(pathName)/\(sbName)_\(itName).csv"

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
                        
                        addContent(text: newRow)
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
            debugPrint("\(lc),\(lnc),\(sc),\(snc)")
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
        let r = 0.0125*2
        var lc = 0
        var sc = 0
        var lnc = 0
        var snc = 0
        for v in values {
            if v > current {
                if (v - current)/current >= r {
                    lc += 1
                }else{
                    lnc += 1
                }
            }else{
                if (current - v)/v >= r {
                    sc += 1
                }else{
                    snc += 1
                }
            }
        }
        
        if lc > 0 || sc > 0 {
            if lc > sc {
                return "long"
            }
            return "short"
        }else {
            if lnc > snc {
                return "LN"
            }
            return "SN"
        }
    }
    
    
}
