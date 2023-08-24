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

func modelValidation() {
    
    if let midRow = csvArrs?.rows[csvIndex] {
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
        
    }
    
}

func loadCSV() {
    
    do {
        
        let path = "/Users/xuanyuan/Downloads/1h/ALPHAUSDT_1h_1h.csv"
        
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

