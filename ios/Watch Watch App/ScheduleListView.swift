//
//  ScheduleListView.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import SwiftUI

struct ScheduleListView: View {
    @State private var flows: [PeriodDto] = []
    
    var body: some View {
        ScrollView {
            if flows.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("暂无日程")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(flows.indices, id: \.self) { index in
                        FlowCardView(flow: flows[index])
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("日程")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFlows()
        }
        .refreshable {
            loadFlows()
        }
    }
    
    private func loadFlows() {
        print("🔄 [ScheduleListView] 开始加载日程")
        let loadedFlows = DataHelper.getUpcomingFlows(limit: 10)
        flows = loadedFlows
        print("✅ [ScheduleListView] 日程加载完成，共 \(loadedFlows.count) 条")
        
        if loadedFlows.isEmpty {
            print("⚠️ [ScheduleListView] 没有找到即将到来的日程")
        } else {
            for (index, flow) in loadedFlows.enumerated() {
                print("📅 [ScheduleListView] 日程 \(index + 1): \(flow.name ?? "未命名") - \(Date(timeIntervalSince1970: TimeInterval(flow.startTime)))")
            }
        }
    }
}

struct FlowCardView: View {
    let flow: PeriodDto
    
    var body: some View {
        let startTime = Date(timeIntervalSince1970: TimeInterval(flow.startTime))
        let endTime = Date(timeIntervalSince1970: TimeInterval(flow.endTime))
        let now = Date()
        let isOngoing = now >= startTime && now < endTime
        let timeToStart = startTime.timeIntervalSince(now)
        
        VStack(alignment: .leading, spacing: 6) {
            // 日程名称
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Text(flow.name ?? "未命名日程")
                    .font(.headline)
                    .lineLimit(1)
            }
            
            // 地点
            if let location = flow.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // 时间信息
            HStack {
                Text(formatTime(startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isOngoing {
                    Text("正在进行")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if timeToStart > 0 {
                    let minutes = Int(timeToStart / 60)
                    if minutes < 60 {
                        Text("\(minutes)分钟后")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        let hours = minutes / 60
                        Text("\(hours)小时后")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ScheduleListView()
    }
}

