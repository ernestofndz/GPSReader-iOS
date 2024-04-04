//
//  SignalStrength.swift
//  GPS Reader
//
//  Created by Ernesto Fernandez on 5/4/24.
//

import Foundation

enum SignalStrength {

    case notDetermined, none, poor, average, good, full

    var bars: Int {
        switch self {
        case .notDetermined, .none: return 0
        case .poor: return 1
        case .average: return 2
        case .good: return 3
        case .full: return 4
        }
    }

}
