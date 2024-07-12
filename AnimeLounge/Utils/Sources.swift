//
//  Sources.swift
//  AnimeLounge
//
//  Created by Francesco on 23/06/24.
//

import Foundation

enum MediaSource: String {
    case animeWorld = "AnimeWorld"
    case gogoanime = "GoGoAnime"
    case animeheaven = "AnimeHeaven"
    case animefire = "AnimeFire"
    case kuramanime = "Kuramanime"
    case latanime = "Latanime"
    case anime3rb = "Anime3rb"
    case animetoast = "AnimeToast"
}

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
