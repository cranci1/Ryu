//
//  AnimeInfo+Struct.swift
//  Ryu
//
//  Created by Francesco on 05/10/24.
//

import Foundation

struct AnilibriaResponse: Codable {
    let names: Names
    let description: String
    let season: Season
    let player: Player
    
    enum CodingKeys: String, CodingKey {
        case names, description, season
        case player
    }
}

struct Names: Codable {
    let ru: String
    let en: String
}

struct Season: Codable {
    let year: Int
    let string: String
}

struct Player: Codable {
    let list: [String: EpisodeInfo]
}

struct EpisodeInfo: Codable {
    let hls: HLS
}

struct HLS: Codable {
    let fhd: String?
    let hd: String?
    let sd: String?
}
