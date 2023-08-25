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
let csvTestPath = "/Users/xuanyuan/py/merged_8-17-30m.csv"


func modelValidation() {
    
    if let midRow = csvArrs?.rows[csvIndex] {
        allCount = midRow.count
        let iRank = midRow["iRank"]?.doubleValue() ?? 0
        let minRate = midRow["minRate"]?.doubleValue() ?? 0
        let maxRate = midRow["maxRate"]?.doubleValue() ?? 0
        let volatility = midRow["volatility"]?.doubleValue() ?? 0
        let sharp = midRow["sharp"]?.doubleValue() ?? 0
        let signal = midRow["signal"]?.doubleValue() ?? 0
        let result = midRow["result"] ?? ""
        
        debugPrint(iRank)
        debugPrint(minRate)
        debugPrint(maxRate)
        debugPrint(volatility)
        debugPrint(sharp)
        debugPrint(signal)
        debugPrint(result)
        
        let dic = [
                "input":
                    [
                        iRank,
                        minRate,
                        volatility,
                        sharp,
                        signal
                    ]
            ]
        
        predictLocal3(dic, interval: "3m") { res in
            if result == "long" {
                if result == res {
                    bingoLong += 1
                }else if res == "short" {
                    errorLong += 1
                }
            }else if result == "short" {
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
        let longRate = Double(bingoLong)/Double(allCount)
        let shortRate = Double(bingoShort)/Double(allCount)
        let LNRate = Double(bingoLN)/Double(allCount)
        let SNRate = Double(bingoSN)/Double(allCount)
        let eLongRate = Double(errorLong)/Double(allCount)
        let eShortRate = Double(errorShort)/Double(allCount)

        debugPrint("long rate: \(longRate)")
        debugPrint("short rate: \(shortRate)")
        debugPrint("LN rate: \(LNRate)")
        debugPrint("SN rate: \(SNRate)")

        exit(0)
        return
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now()+0.1) {
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
        
        modelValidation()
        
    }catch {
        
    }
}

func predictLocal3(_ dic: any Content,interval: String,callback: SKCallback?) {
    
    do {
        let response = try kApp.client.post("http://127.0.0.1:5001/predict") { req in
            try req.content.encode(dic)
        }.wait()

        if response.status == .ok {
            // 解码并打印响应
            let prediction = try response.content.decode([Double].self)
            print(prediction)
//            let res = prediction.first ?? ""
//            if let ss = callback {
//                ss(res)
//            }
//            print(res)
        } else {
            print("Error: \(response.status)")
            if let ss = callback {
                ss("\(response.status)")
            }
        }
    } catch {
        print("Error: \(error)")
        if let ss = callback {
            ss("\(error.localizedDescription)")
        }
    }
    
}

