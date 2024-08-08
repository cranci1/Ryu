//
//  Login.swift
//  AnimeLounge
//
//  Created by Francesco on 08/08/24.
//

import UIKit

class AniListLogin {
    static let clientID = "19551"
    static let redirectURI = "animelounge://anilist"
    
    static let authorizationEndpoint = "https://anilist.co/api/v2/oauth/authorize"
    
    static func authenticate() {
        let urlString = "\(authorizationEndpoint)?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code"
        print(urlString)
        guard let url = URL(string: urlString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("Safari opened successfully")
                } else {
                    print("Failed to open Safari")
                }
            }
        } else {
            print("Cannot open URL")
        }
    }
    
    func handleRedirect(url: URL) {
        print("Redirect URL: \(url)")
        
        guard let code = url.queryParameters?["code"] else {
            print("Failed to extract authorization code")
            return
        }
        
        print("Authorization code received: \(code)")
        AniListToken.exchangeAuthorizationCodeForToken(code: code)
    }
}

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
        return params
    }
}
