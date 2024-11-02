//
//  Episode+Struct.swift
//  Ryu
//
//  Created by Francesco on 28/10/24.
//

import UIKit

enum VideoLanguage: Int {
    case germanDub = 1
    case englishSub = 2
    case germanSub = 3
    
    var description: String {
        switch self {
        case .germanDub: return "German (Dubbed)"
        case .englishSub: return "English (Subtitled)"
        case .germanSub: return "German (Subtitled)"
        }
    }
}

enum VideoHost {
    case vidoza
    case voe
    
    var description: String {
        switch self {
        case .vidoza: return "Vidoza"
        case .voe: return "Voe"
        }
    }
}

struct VideoLink {
    let url: String
    let language: VideoLanguage
    let host: VideoHost
}
