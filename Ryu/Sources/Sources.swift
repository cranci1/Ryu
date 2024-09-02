//
//  Sources.swift
//  Ryu
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
    case jkanime = "JKanime"
    case anime3rb = "Anime3rb"
    case hianime = "HiAnime"
    case zorotv = "ZoroTv"
}

extension MediaSource {
    var displayName: String {
        switch self {
        case .animeWorld: return "AnimeWorld"
        case .gogoanime: return "GoGoAnime"
        case .animeheaven: return "AnimeHeaven"
        case .animefire: return "AnimeFire"
        case .kuramanime: return "Kuramanime"
        case .jkanime: return "JKanime"
        case .anime3rb: return "Anime3rb"
        case .hianime: return "HiAnime"
        case .zorotv: return "ZoroTv"
        }
    }
}
