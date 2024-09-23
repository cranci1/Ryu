//
//  Collection.swift
//  Ryu
//
//  Created by Francesco on 23/09/24.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
