//
//  Item.swift
//  DoNothing
//
//  Created by Wiktor Bramer on 12/01/2026.
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
