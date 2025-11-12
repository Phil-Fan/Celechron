//
//  PeriodDto.swift
//  Watch Watch App
//
//  Shared data models matching Pigeon definitions
//  This ensures consistency with the main app and widget extensions
//  These types match the structures in ios/Runner/FlowMessenger.swift
//

import Foundation

/// Period type enumeration matching Pigeon definition
enum PeriodTypeDto: Int, Codable {
  case classes = 0
  case test = 1
  case user = 2
  case flow = 3
}

/// Period data transfer object matching Pigeon definition
struct PeriodDto: Codable {
  var uid: String
  var type: PeriodTypeDto
  var name: String? = nil
  var startTime: Int64
  var endTime: Int64
  var location: String? = nil
}

/// Flow message containing list of periods
struct FlowMessage: Codable {
  var flowListDto: [PeriodDto?]
}

