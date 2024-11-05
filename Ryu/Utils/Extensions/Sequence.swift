//
//  Sequence.swift
//  Ryu
//
//  Created by Francesco on 05/11/24.
//

import Foundation

extension Sequence where Element: Hashable {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
