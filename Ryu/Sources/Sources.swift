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
    case anime3rb = "Anime3rb"
    case hianime = "HiAnime"
    case hanashi = "Hanashi"
    case anilibria = "Anilibria"
    case animesrbija = "AnimeSRBIJA"
    case aniworld = "AniWorld"
    case tokyoinsider = "TokyoInsider"
    case anivibe = "AniVibe"
    case animeunity = "AnimeUnity"
    case animeflv = "AnimeFLV"
    case animebalkan = "AnimeBalkan"
    case anibunker = "AniBunker"
}

extension MediaSource {
    var displayName: String {
        switch self {
        case .animeWorld: return "AnimeWorld"
        case .gogoanime: return "GoGoAnime"
        case .animeheaven: return "AnimeHeaven"
        case .animefire: return "AnimeFire"
        case .kuramanime: return "Kuramanime"
        case .anime3rb: return "Anime3rb"
        case .hianime: return "HiAnime"
        case .hanashi: return "Hanashi"
        case .anilibria: return "Anilibria"
        case .animesrbija: return "AnimeSRBIJA"
        case .aniworld: return "AniWorld"
        case .tokyoinsider: return "TokyoInsider"
        case .anivibe: return "AniVibe"
        case .animeunity: return "AnimeUnity"
        case .animeflv: return "AnimeFLV"
        case .animebalkan: return "AnimeBalkan"
        case .anibunker: return "AniBunker"
        }
    }
}
