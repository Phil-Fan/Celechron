//
//  NetworkHelper.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation
import os.log

class NetworkHelper {
    private static let logger = OSLog(subsystem: "top.celechron.celechron.watch", category: "NetworkHelper")
    
    static func getECardAccount(synjonesAuth: String) async throws -> String? {
        let urlString = "https://elife.zju.edu.cn/berserker-app/ykt/tsm/getCampusCards"
        os_log("🌐 [Network] 开始获取校园卡账户，URL: %{public}@", log: logger, type: .info, urlString)
        
        guard let url = URL(string: urlString) else {
            os_log("❌ [Network] URL无效", log: logger, type: .error)
            print("❌ [Network] URL无效: \(urlString)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer " + synjonesAuth, forHTTPHeaderField: "Synjones-Auth")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0", forHTTPHeaderField: "User-Agent")
        
        os_log("📤 [Network] 发送请求，认证头长度: %d", log: logger, type: .info, synjonesAuth.count)
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                os_log("📥 [Network] 收到响应，状态码: %d，数据大小: %d bytes", log: logger, type: .info, httpResponse.statusCode, data.count)
                print("📥 [Network] HTTP状态码: \(httpResponse.statusCode)，数据大小: \(data.count) bytes")
                
                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [Network] 响应内容: \(errorString)")
                    }
                }
            }
            
            guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                os_log("❌ [Network] JSON解析失败，不是字典类型", log: logger, type: .error)
                print("❌ [Network] JSON解析失败，不是字典类型")
                return nil
            }
            
            guard let dataDict = jsonDict["data"] as? [String: Any] else {
                os_log("❌ [Network] JSON中没有data字段", log: logger, type: .error)
                print("❌ [Network] JSON中没有data字段，keys: \(jsonDict.keys.joined(separator: ", "))")
                return nil
            }
            
            guard let cardList = dataDict["card"] as? [[String: Any]] else {
                os_log("❌ [Network] data中没有card数组", log: logger, type: .error)
                print("❌ [Network] data中没有card数组，data keys: \(dataDict.keys.joined(separator: ", "))")
                return nil
            }
            
            os_log("✅ [Network] 找到 %d 张卡片", log: logger, type: .info, cardList.count)
            print("✅ [Network] 找到 \(cardList.count) 张卡片")
            
            // 选择余额最高的卡
            let account = cardList.max(by: { ($0["db_balance"] as? Int ?? 0) < ($1["db_balance"] as? Int ?? 0) })?["account"] as? String
            
            if let account = account {
                os_log("✅ [Network] 选择的账户: %{public}@", log: logger, type: .info, account)
                print("✅ [Network] 选择的账户: \(account)")
            } else {
                os_log("❌ [Network] 无法从卡片列表中找到账户", log: logger, type: .error)
                print("❌ [Network] 无法从卡片列表中找到账户")
            }
            
            return account
        } catch {
            os_log("❌ [Network] 网络请求失败: %{public}@", log: logger, type: .error, error.localizedDescription)
            print("❌ [Network] 网络请求失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func getBarcode(synjonesAuth: String, eCardAccount: String) async throws -> String? {
        os_log("🌐 [Network] 开始获取付款码，账户: %{public}@", log: logger, type: .info, eCardAccount)
        
        guard let encodedAccount = eCardAccount.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            os_log("❌ [Network] 账户编码失败", log: logger, type: .error)
            print("❌ [Network] 账户编码失败: \(eCardAccount)")
            return nil
        }
        
        let urlString = "https://elife.zju.edu.cn/berserker-app/ykt/tsm/batchGetBarCodeGet?account=\(encodedAccount)&payacc=%23%23%23&paytype=1&synAccessSource=app"
        
        guard let url = URL(string: urlString) else {
            os_log("❌ [Network] URL无效", log: logger, type: .error)
            print("❌ [Network] URL无效: \(urlString)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("bearer \(synjonesAuth)", forHTTPHeaderField: "synjones-auth")
        
        os_log("📤 [Network] 发送付款码请求", log: logger, type: .info)
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                os_log("📥 [Network] 收到付款码响应，状态码: %d，数据大小: %d bytes", log: logger, type: .info, httpResponse.statusCode, data.count)
                print("📥 [Network] HTTP状态码: \(httpResponse.statusCode)，数据大小: \(data.count) bytes")
                
                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [Network] 响应内容: \(errorString)")
                    }
                }
            }
            
            guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                os_log("❌ [Network] JSON解析失败", log: logger, type: .error)
                print("❌ [Network] JSON解析失败")
                return nil
            }
            
            guard let dataDict = jsonDict["data"] as? [String: Any] else {
                os_log("❌ [Network] JSON中没有data字段", log: logger, type: .error)
                print("❌ [Network] JSON中没有data字段，keys: \(jsonDict.keys.joined(separator: ", "))")
                return nil
            }
            
            guard let barcodeArray = dataDict["barcode"] as? [String] else {
                os_log("❌ [Network] data中没有barcode数组", log: logger, type: .error)
                print("❌ [Network] data中没有barcode数组，data keys: \(dataDict.keys.joined(separator: ", "))")
                return nil
            }
            
            guard let barcode = barcodeArray.first else {
                os_log("❌ [Network] barcode数组为空", log: logger, type: .error)
                print("❌ [Network] barcode数组为空")
                return nil
            }
            
            os_log("✅ [Network] 成功获取付款码，长度: %d", log: logger, type: .info, barcode.count)
            print("✅ [Network] 成功获取付款码: \(barcode)")
            
            return barcode
        } catch {
            os_log("❌ [Network] 网络请求失败: %{public}@", log: logger, type: .error, error.localizedDescription)
            print("❌ [Network] 网络请求失败: \(error.localizedDescription)")
            throw error
        }
    }
}

