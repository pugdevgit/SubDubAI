//
//  Item.swift
//  SubDubAI
//
//  Created by Oleg on 21.11.2025.
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
