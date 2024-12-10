//
//  ModuleStruct.swift
//  Ryu
//
//  Created by Francesco on 10/12/24.
//

import Foundation

struct ModuleStruct: Codable {
    let name: String
    let version: String
    let author: Author
    let iconURL: String
    let stream: String
    let module: [Module]

    struct Author: Codable {
        let name: String
        let website: String
    }

    struct Module: Codable {
        let search: Search
        let featured: Featured
        let details: Details
        let episodes: Episodes

        struct Search: Codable {
            let url: String
            let parameter: String
            let documentSelector: String
            let title: String
            let image: Image
            let href: String

            struct Image: Codable {
                let url: String
                let attribute: String
            }
        }

        struct Featured: Codable {
            let url: String
            let documentSelector: String
            let title: String
            let image: Image
            let href: String

            struct Image: Codable {
                let url: String
                let attribute: String
            }
        }

        struct Details: Codable {
            let baseURL: String
            let aliases: Aliases
            let synopsis: String
            let airdate: String
            let stars: String

            struct Aliases: Codable {
                let selector: String
                let attribute: String
            }
        }

        struct Episodes: Codable {
            let selector: String
        }
    }
}
