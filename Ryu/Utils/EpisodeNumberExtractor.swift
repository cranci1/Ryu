//
//  EpisodeNumberExtractor.swift
//  Ryu
//
//  Created by Francesco on 04/11/24.
//

import Foundation

class EpisodeNumberExtractor {
    static func extract(from episodeNumberString: String) -> Int {
        if episodeNumberString.hasPrefix("S") {
            let parts = episodeNumberString.split(separator: "E")
            if parts.count == 2, let episodePart = Int(parts[1]) {
                return episodePart
            }
        }
        
        return Int(episodeNumberString) ?? 0
    }
}

