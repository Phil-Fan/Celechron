//
//  PeriodDto.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation

enum PeriodTypeDto: Int, Codable {
    case classes = 0
    case test = 1
    case user = 2
    case flow = 3
}

struct PeriodDto: Codable {
    var uid: String
    var type: PeriodTypeDto
    var name: String?
    var startTime: Int64
    var endTime: Int64
    var location: String?
}

