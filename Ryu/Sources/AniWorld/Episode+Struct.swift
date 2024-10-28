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

struct VidozaLink {
    let url: String
    let language: VideoLanguage
}
