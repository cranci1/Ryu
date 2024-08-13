//
//  URL.swift
//  Ryu
//
//  Created by Francesco on 13/08/24.
//

import Foundation

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        var params = [String: String]()
        for item in queryItems {
            params[item.name] = item.value
        }
    }
}

