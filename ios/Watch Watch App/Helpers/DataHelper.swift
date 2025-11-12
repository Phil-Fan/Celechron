//
//  DataHelper.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation
import os.log

class DataHelper {
    private static let logger = OSLog(subsystem: "top.celechron.celechron.watch", category: "DataHelper")
    
    static func getFlowList() -> [PeriodDto] {
        #if DEBUG
        let suiteName = "group.top.celechron.celechron.debug"
        #else
        let suiteName = "group.top.celechron.celechron"
        #endif
        
        os_log("📊 [DataHelper] 开始读取日程数据，SuiteName: %{public}@", log: logger, type: .info, suiteName)
        
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            os_log("❌ [DataHelper] 无法创建UserDefaults实例，SuiteName: %{public}@", log: logger, type: .error, suiteName)
            print("❌ [DataHelper] 无法创建UserDefaults实例，请检查App Group配置: \(suiteName)")
            return []
        }
        
        os_log("✅ [DataHelper] UserDefaults实例创建成功", log: logger, type: .info)
        
        guard let data = userDefaults.data(forKey: "flowList") else {
            os_log("⚠️ [DataHelper] UserDefaults中没有flowList数据", log: logger, type: .info)
            print("⚠️ [DataHelper] UserDefaults中没有找到flowList数据")
            
            // 列出所有keys用于调试
            if let allKeys = userDefaults.dictionaryRepresentation().keys as? [String] {
                print("📋 [DataHelper] UserDefaults中的所有keys: \(allKeys.joined(separator: ", "))")
            }
            
            return []
        }
        
        os_log("✅ [DataHelper] 找到flowList数据，大小: %d bytes", log: logger, type: .info, data.count)
        print("✅ [DataHelper] 找到flowList数据，大小: \(data.count) bytes")
        
        guard let flowList = try? JSONDecoder().decode([PeriodDto?].self, from: data) else {
            os_log("❌ [DataHelper] JSON解码失败", log: logger, type: .error)
            print("❌ [DataHelper] JSON解码失败，数据可能格式不正确")
            
            // 尝试打印原始数据的前100个字符用于调试
            if let dataString = String(data: data.prefix(100), encoding: .utf8) {
                print("📄 [DataHelper] 数据预览: \(dataString)...")
            }
            
            return []
        }
        
        let validFlows = flowList.compactMap { $0 }
        os_log("✅ [DataHelper] 成功解析日程数据，总数: %d，有效: %d", log: logger, type: .info, flowList.count, validFlows.count)
        print("✅ [DataHelper] 成功解析日程数据，总数: \(flowList.count)，有效: \(validFlows.count)")
        
        // 打印所有日程详情用于调试
        if !validFlows.isEmpty {
            print("📋 [DataHelper] 所有日程详情:")
            for (index, flow) in validFlows.enumerated() {
                let startDate = Date(timeIntervalSince1970: TimeInterval(flow.startTime))
                let endDate = Date(timeIntervalSince1970: TimeInterval(flow.endTime))
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd HH:mm"
                print("  [\(index + 1)] \(flow.name ?? "未命名") | \(formatter.string(from: startDate)) - \(formatter.string(from: endDate)) | \(flow.location ?? "无地点") | 类型: \(flow.type.rawValue)")
            }
        }
        
        return validFlows
    }
    
    static func getUpcomingFlows(limit: Int = 10) -> [PeriodDto] {
        os_log("📅 [DataHelper] 开始获取即将到来的日程，限制: %d", log: logger, type: .info, limit)
        
        let flowList = getFlowList()
        let currentTime = Date().timeIntervalSince1970
        
        os_log("⏰ [DataHelper] 当前时间戳: %.0f", log: logger, type: .info, currentTime)
        
        let upcomingFlows = flowList.filter { period in
            let timeToStart = TimeInterval(period.startTime) - currentTime
            let timeToEnd = TimeInterval(period.endTime) - currentTime
            // 显示未来48小时内开始或正在进行的日程
            return timeToEnd > 0 && timeToStart <= 172800
        }
        
        let sortedFlows = Array(upcomingFlows.sorted { $0.startTime < $1.startTime }.prefix(limit))
        
        os_log("✅ [DataHelper] 筛选后即将到来的日程数量: %d", log: logger, type: .info, sortedFlows.count)
        print("✅ [DataHelper] 筛选后即将到来的日程数量: \(sortedFlows.count)")
        
        // 打印即将到来的日程详情
        if !sortedFlows.isEmpty {
            print("📅 [DataHelper] 即将到来的日程详情:")
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            for (index, flow) in sortedFlows.enumerated() {
                let startDate = Date(timeIntervalSince1970: TimeInterval(flow.startTime))
                let endDate = Date(timeIntervalSince1970: TimeInterval(flow.endTime))
                let timeToStart = TimeInterval(flow.startTime) - currentTime
                let hoursToStart = Int(timeToStart / 3600)
                let minutesToStart = Int((timeToStart.truncatingRemainder(dividingBy: 3600)) / 60)
                print("  [\(index + 1)] \(flow.name ?? "未命名") | \(formatter.string(from: startDate)) - \(formatter.string(from: endDate)) | \(hoursToStart)小时\(minutesToStart)分钟后开始")
            }
        }
        
        return sortedFlows
    }
}

