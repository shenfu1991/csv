//
//  File.swift
//
//
//  Created by xuanyuan on 2023/6/3.
//

import Vapor
import CoreML

extension Double {
    
    func fmt(x: Int = 6) ->Double {
        let valueStr = self.strXF(x: x)
        return Double(valueStr) ?? 0
    }
    
    func str2F() ->String{
        return String(format: "%.2f", self)
    }
    
    func strXF(x: Int) ->String{
        return String(format: "%.\(x)f", self)
    }
    
    func strBTF() ->String{
        if self < 1 {
            return String(format: "%.6f", self)
        }
        return String(format: "%.2f", self)
    }
}


extension CoreViewController {
    func string2T(day: String) ->TimeInterval {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        format.timeZone = TimeZone.init(identifier: TimeZone.current.identifier)
        return format.date(from: day)?.timeIntervalSince1970 ?? 0
    }
}


func string2Json(text: String) -> [String:Any] {
    let data = Data(text.utf8)
    do {
        // make sure this JSON is in the format we expect
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
           return json
        }
    } catch let error as NSError {
        print("Failed to load: \(error.localizedDescription)")
    }
    return [:]
}

func json2String(json: [String: Any]) ->String {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)
        return jsonString ?? ""
//        print(jsonString!)
        // Output: {"city":"New York","name":"John","age":30}
    } catch {
        print(error.localizedDescription)
    }
    return ""
}

func handleData(data: Any?) ->Double {
    
    if let da = data as? String {
        return Double(da) ?? 0
    }else if let da = data as? Double {
        return da
    }
    
    return 0
}

func getTime() ->String {
    let format = DateFormatter()
    format.dateFormat = "HH:mm:ss"
    return format.string(from: Date())
}

func modelRes(md: MLModel,dict: [String: Any],symbol:String,interval: String) ->String{
    let pro = try? MLDictionaryFeatureProvider(dictionary: dict)
    if let res = try? md.prediction(from: pro!) {
        if let num = res.featureValue(for: "result") {
            let str = (num).stringValue
            debugPrint("num=\(str)-\(symbol)-\(interval) \(getTime())")
//            if str == "none" {
//                debugPrint("none=\(dict)")
//            }
            return str
        }
    }else{
        debugPrint("模型加载失败: \(dict)")
       
    }
    return ""
}

extension String {
    func extractNumbersFromString() -> String {
        let regex = try! NSRegularExpression(pattern: "\\d+")
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        let numbers = matches.map { String(self[Range($0.range, in: self)!]) }
        return numbers.joined()
    }
    
    func getDigial() ->Int {
        return Int(extractNumbersFromString()) ?? -1
    }
    
    func doubleValue() ->Double {
        return Double(self) ?? 0
    }
}
