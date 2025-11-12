//
//  ScheduleProvider.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation
import Combine
import os.log

@MainActor
class ScheduleProvider: ObservableObject {
    private let logger = OSLog(subsystem: "top.celechron.celechron.watch", category: "ScheduleProvider")
    
    @Published var flows: [PeriodDto] = []
    @Published var isLoading: Bool = false
    @Published var hasData: Bool = true  // 用于区分"无数据"和"数据未同步"
    
    func loadFlows(limit: Int = 10) {
        let timestamp = DateFormatter()
        timestamp.dateFormat = "HH:mm:ss"
        let timeString = timestamp.string(from: Date())
        
        print("🔄 [ScheduleProvider] [\(timeString)] 开始加载日程，限制: \(limit)")
        os_log("🔄 [ScheduleProvider] 开始加载日程，限制: %d", log: logger, type: .info, limit)
        isLoading = true
        
        // 检查 UserDefaults 中是否有数据
        #if DEBUG
        let suiteName = "group.top.celechron.celechron.debug"
        #else
        let suiteName = "group.top.celechron.celechron"
        #endif
        
        let userDefaults = UserDefaults(suiteName: suiteName)
        let hasFlowListData = userDefaults?.data(forKey: "flowList") != nil
        
        if hasFlowListData {
            if let data = userDefaults?.data(forKey: "flowList") {
                print("📦 [ScheduleProvider] [\(timeString)] UserDefaults中有数据，大小: \(data.count) bytes")
                os_log("📦 [ScheduleProvider] UserDefaults中有数据，大小: %d bytes", log: logger, type: .info, data.count)
            }
        } else {
            print("⚠️ [ScheduleProvider] [\(timeString)] UserDefaults中没有flowList数据")
            os_log("⚠️ [ScheduleProvider] UserDefaults中没有flowList数据", log: logger, type: .info)
        }
        
        let loadedFlows = DataHelper.getUpcomingFlows(limit: limit)
        flows = loadedFlows
        isLoading = false
        hasData = hasFlowListData  // 标记是否有数据源
        
        print("✅ [ScheduleProvider] [\(timeString)] 日程加载完成，共 \(loadedFlows.count) 条")
        os_log("✅ [ScheduleProvider] 日程加载完成，共 %d 条", log: logger, type: .info, loadedFlows.count)
        
        if loadedFlows.isEmpty {
            if !hasFlowListData {
                print("⚠️ [ScheduleProvider] [\(timeString)] UserDefaults中没有数据，需要主应用同步")
                os_log("⚠️ [ScheduleProvider] UserDefaults中没有数据，需要主应用同步", log: logger, type: .info)
            } else {
                print("⚠️ [ScheduleProvider] [\(timeString)] 没有找到即将到来的日程（48小时内）")
                os_log("⚠️ [ScheduleProvider] 没有找到即将到来的日程", log: logger, type: .info)
            }
        } else {
            print("📋 [ScheduleProvider] [\(timeString)] 已加载的日程列表:")
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            for (index, flow) in loadedFlows.enumerated() {
                let startDate = Date(timeIntervalSince1970: TimeInterval(flow.startTime))
                let endDate = Date(timeIntervalSince1970: TimeInterval(flow.endTime))
                print("  [\(index + 1)] \(flow.name ?? "未命名") | \(formatter.string(from: startDate)) - \(formatter.string(from: endDate)) | \(flow.location ?? "无地点")")
                os_log("📅 [ScheduleProvider] 日程 %d: %{public}@ - %{public}@", log: logger, type: .info, index + 1, flow.name ?? "未命名", formatter.string(from: startDate))
            }
        }
    }
}

