//
//  Token.swift
//  AnimeLounge
//
//  Created by Francesco on 08/08/24.
//

import UIKit

class AniListToken {
    
    static let clientID = "19551"
    static let clientSecret = "fk8EgkyFbXk95TbPwLYQLaiMaNIryMpDBwJsPXoX"
    static let redirectURI = "animelounge://anilist"
    
    static let tokenEndpoint = "https://anilist.co/api/v2/oauth/token"
    
    static func exchangeAuthorizationCodeForToken(code: String) {
        print("Exchanging authorization code for access token...")
        
        guard let url = URL(string: tokenEndpoint) else {
            print("Invalid token endpoint URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "grant_type=authorization_code&client_id=\(clientID)&client_secret=\(clientSecret)&redirect_uri=\(redirectURI)&code=\(code)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let accessToken = json["access_token"] as? String {
                        print("Access Token: \(accessToken)")
                        UserDefaults.standard.set(accessToken, forKey: "accessToken")
                    } else {
                        print("Unexpected response: \(json)")
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
}
