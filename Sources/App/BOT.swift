
//
import Foundation
import SwiftCSV
import CoreML

extension CoreViewController {
    
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
    

}
