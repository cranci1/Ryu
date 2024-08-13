//
//  String.swift
//  Ryu
//
//  Created by Francesco on 13/08/24.
//

import Foundation

extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}
