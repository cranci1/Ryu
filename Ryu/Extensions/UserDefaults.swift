//
//  UserDefaults.swift
//  Ryu
//
//  Created by Francesco on 13/08/24.
//

import Foundation

extension UserDefaults {
    var selectedMediaSource: MediaSource? {
        get {
            if let source = string(forKey: "selectedMediaSource") {
                return MediaSource(rawValue: source)
            }
            return nil
        }
        set {
            set(newValue?.rawValue, forKey: "selectedMediaSource")
        }
    }
}

