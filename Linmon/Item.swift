//
//  Item.swift
//  Linmon
//
//  Created by Linfeng on 10/31/26.
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
