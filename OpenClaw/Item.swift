//
//  Item.swift
//  OpenClaw
//
//  Created by Brandon Price on 2/17/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
