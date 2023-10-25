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
let testFileArr = ["API3USDT_15m_15m_ls.csv",
                  "ARKMUSDT_15m_15m_ls.csv",
                   "BCHUSDT_15m_15m_ls.csv",
                   "COMBOUSDT_15m_15m_ls.csv",
                   "CYBERUSDT_15m_15m_ls.csv",
                   "GTCUSDT_15m_15m_ls.csv",
                   "MAVUSDT_15m_15m_ls.csv",
//                   "OGNUSDT_15m_15m_ls.csv",
//                   "PENDLEUSDT_15m_15m_ls.csv",
//                   "SEIUSDT_15m_15m_ls.csv",
//                   "SKLUSDT_15m_15m_ls.csv",
//                   "STXUSDT_15m_15m_ls.csv",
//                   "UNFIUSDT_15m_15m_ls.csv",
//                   "WLDUSDT_15m_15m_ls.csv",
//                   "YGGUSDT_15m_15m_ls.csv",
                   "ZENUSDT_15m_15m_ls.csv",]
//let testFileArr = ["BCHUSDT_15m_15m_ls.csv"]
var csvTestPath = "/Users/xuanyuan/Documents/csv-sm/ls/"
let port = 6601
var d: TimeInterval = 0
var totalLong = 0
var totalShort = 0
var textIdx = 0

var totalLongScore = 0
var totalShortScore = 0


func modelValidation() {
    
    if let midRow = csvArrs?.rows[csvIndex] {

//        "rsi,so,mfi,cci,result\n"
        let rsi = midRow["rsi"]?.doubleValue() ?? 0
        let so = midRow["so"]?.doubleValue() ?? 0
        let mfi = midRow["mfi"]?.doubleValue() ?? 0
        let cci = midRow["cci"]?.doubleValue() ?? 0
        let result = midRow["result"] ?? ""
//        let rsi_so = rsi*so
//        let mfi_cci = mfi*cci

        
        let dic = [
                "input":
                    [
                       rsi,
                       so,
                       mfi,
                       cci,
//                       rsi_so,
//                       mfi_cci
                    ]
            ]
        
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
    }else {
        debugPrint("read files error")
//        nextF()
    }
    
}

func nextT() {
    csvIndex += 1
    if csvIndex >= allCount {
        debugPrint("----all finished----")
        let longRate = Double(bingoLong)/Double(totalLong)
        let shortRate = Double(bingoShort)/Double(totalShort)
//        let LNRate = Double(bingoLN)/Double(allCount)
//        let SNRate = Double(bingoSN)/Double(allCount)
        let eLongRate = Double(errorLong)/Double(allCount)
        let eShortRate = Double(errorShort)/Double(allCount)

        debugPrint("long rate: \(bingoLong)/\(totalLong)     R:\(longRate)")
        debugPrint("short rate: \(bingoShort)/\(totalShort)   R:\(shortRate)")
//        debugPrint("LN rate: \(bingoLN)       R:\(LNRate)")
//        debugPrint("SN rate: \(bingoSN)    R:\(SNRate)")
        debugPrint("eLongRate rate: \(errorLong)        R:\(eLongRate)")
        debugPrint("eShortRate rate: \(errorShort)     R:\(eShortRate)")
        
        let longScore = bingoLong-errorLong*2
        let shortScore = bingoShort-errorShort*2
        debugPrint("long score: \(longScore)")
        debugPrint("short score: \(shortScore)")
        totalLongScore += longScore
        totalShortScore += shortScore

        let sub = Date().timeIntervalSince1970 - d
        debugPrint("time=\(sub)")
        nextF()
        return
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now()+0.00001) {
        modelValidation()
    }
    
}

func nextF() {
    textIdx += 1
    if textIdx >= testFileArr.count {
        debugPrint("----finished---")
        debugPrint("total long score: \(totalLongScore)")
        debugPrint("total short score: \(totalShortScore)")
        exit(0)
    }
     csvIndex = 0
     allCount = 0
     bingoLong = 0
     bingoShort = 0
     bingoLN = 0
     bingoSN = 0
     errorLong = 0
     errorShort = 0
    
    loadCSV()
}

func loadCSV() {
    
    do {
        let name = testFileArr[textIdx]
        let path = csvTestPath + name
        print(path)
        
        let csvFileUrl = URL(fileURLWithPath: path)
        
        let csvFile = try CSV<Named>(url: csvFileUrl)
        
        // 获取所有行
        csvArrs = csvFile
        if textIdx == 0 {
            d = Date().timeIntervalSince1970
        }
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
//       debugPrint(response)
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
            print("Error: \(response.status)")
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

