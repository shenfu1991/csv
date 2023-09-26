//
//  File.swift
//  
//
//  Created by xuanyuan on 2023/8/24.
//

import SwiftCSV
import AsyncHTTPClient
import Vapor

typealias SKCallback = (String) -> Void

var csvArrs: NamedCSV? = nil
var csvIndex = 0
var allCount = 0
var bingoLong = 0
var bingoShort = 0
var bingoLN = 0
var bingoSN = 0
var errorLong = 0
var errorShort = 0
//let csvTestPath = "/Users/xuanyuan/Documents/8-17-30m/ALPHAUSDT_30m_30m.csv"
//let csvTestPath = "/Users/xuanyuan/Documents/8-17-30m/WOOUSDT_30m_30m_processed.csv"
let csvTestPath = "/Users/xuanyuan/py/merged_csv-t.csv"
let port = 6601
var d: TimeInterval = 0
var totalLong = 0
var totalShort = 0


func modelValidation() {
    
    if let midRow = csvArrs?.rows[csvIndex] {

        let rank = midRow["rank"]?.doubleValue() ?? 0
        let minR = midRow["minR"]?.doubleValue() ?? 0
        let maxR = midRow["maxR"]?.doubleValue() ?? 0
        let minDiffR = midRow["minDiffR"]?.doubleValue() ?? 0
        let maxDiffR = midRow["maxDiffR"]?.doubleValue() ?? 0
        let topRank = midRow["topRank"]?.doubleValue() ?? 0
        let result = midRow["result"] ?? ""
        
//        if result == "LN" || result == "SN" {
//            nextT()
//            return
//        }
        
//        debugPrint(iRank)
//        debugPrint(minRate)
//        debugPrint(maxRate)
//        debugPrint(volatility)
//        debugPrint(sharp)
//        debugPrint(signal)
//        debugPrint(result)
        
        let dic = [
                "input":
                    [
                       rank,
                       minR,
                       maxR,
                       minDiffR,
                       maxDiffR,
                       topRank
             
                    ]
            ]
        
//        let dic = [
//                "input":
//                    [
//                        iRank,
//                        minRate,
//                        maxRate,
//                        volatility,
//                        sharp,
//                        minR,
//                        maxR,
//                        signal
//                    ]
//            ]
        
        predictLocal3(dic, interval: "3m") { res in
            if result == "long" {
                totalLong += 1
                if result == res {
                    bingoLong += 1
                }else if res == "short" {
                    errorLong += 1
                }
            }else if result == "short" {
                totalShort += 1
                if result == res {
                    bingoShort += 1
                }else if res == "long" {
                    errorShort += 1
                }
            }else if result == "LN" {
                if result == res {
                    bingoLN += 1
                }
            }else if result == "SN" {
                if result == res {
                    bingoSN += 1
                }
            }
            nextT()
        }
    }
    
}

func nextT() {
    csvIndex += 1
    if csvIndex >= allCount {
        debugPrint("----all finished----")
        let longRate = Double(bingoLong)/Double(totalLong)
        let shortRate = Double(bingoShort)/Double(totalShort)
        let LNRate = Double(bingoLN)/Double(allCount)
        let SNRate = Double(bingoSN)/Double(allCount)
        let eLongRate = Double(errorLong)/Double(allCount)
        let eShortRate = Double(errorShort)/Double(allCount)

        debugPrint("long rate: \(bingoLong)/\(totalLong)     R:\(longRate)")
        debugPrint("short rate: \(bingoShort)/\(totalShort)   R:\(shortRate)")
        debugPrint("LN rate: \(bingoLN)       R:\(LNRate)")
        debugPrint("SN rate: \(bingoSN)    R:\(SNRate)")
        debugPrint("eLongRate rate: \(errorLong)        R:\(eLongRate)")
        debugPrint("eShortRate rate: \(errorShort)     R:\(eShortRate)")
        
        let longScore = bingoLong-errorLong*2
        let shortScore = bingoShort-errorShort*2
        debugPrint("long score: \(longScore)")
        debugPrint("short score: \(shortScore)")

        let sub = Date().timeIntervalSince1970 - d
        debugPrint("time=\(sub)")
        exit(0)
        return
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now()+0.00001) {
        modelValidation()
    }
    
}

func loadCSV() {
    
    do {
        let path = csvTestPath
        print(path)
        
        let csvFileUrl = URL(fileURLWithPath: path)
        
        let csvFile = try CSV<Named>(url: csvFileUrl)
        
        // 获取所有行
        csvArrs = csvFile
        d = Date().timeIntervalSince1970
        allCount = csvArrs?.rows.count ?? 0
        debugPrint("total: \(allCount)")
        
        modelValidation()
        
    }catch {
        debugPrint("load failed: \(error.localizedDescription)")
    }
}

func predictLocal3(_ dic: any Content,interval: String,callback: SKCallback?) {
    
    do {
        let response = try kApp.client.post("http://127.0.0.1:\(port)/predict") { req in
            try req.content.encode(dic)
        }.wait()
       debugPrint(response)
        if response.status == .ok {
            // 解码并打印响应
            let prediction = try response.content.decode([String].self)
//            print("prediction=\(prediction)")
            let res = prediction.first ?? ""
            if let ss = callback {
                ss(res)
            }
//            print(res)
        } else {
//            print("Error: \(response.status)")
            if let ss = callback {
                ss("\(response.status)")
            }
        }
    } catch {
//        print("Error: \(error)")
        if let ss = callback {
            ss("\(error.localizedDescription)")
        }
    }
    
}

