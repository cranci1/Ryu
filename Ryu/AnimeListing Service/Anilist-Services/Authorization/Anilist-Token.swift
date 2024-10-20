//
//  Token.swift
//  Ryu
//
//  Created by Francesco on 08/08/24.
//

import UIKit
import Security

class AniListToken {
    static let clientID = "19551"
    static let clientSecret = "fk8EgkyFbXk95TbPwLYQLaiMaNIryMpDBwJsPXoX"
    static let redirectURI = "ryu://anilist"
    
    static let tokenEndpoint = "https://anilist.co/api/v2/oauth/token"
    static let serviceName = "me.ryu.AniListToken"
    static let accountName = "AniListAccessToken"
    
    static func saveTokenToKeychain(token: String) -> Bool {
        let tokenData = token.data(using: .utf8)!
        
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: tokenData
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func exchangeAuthorizationCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        print("Exchanging authorization code for access token...")
        
        guard let url = URL(string: tokenEndpoint) else {
            print("Invalid token endpoint URL")
            completion(false)
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
                completion(false)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(false)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let accessToken = json["access_token"] as? String {
                        let success = saveTokenToKeychain(token: accessToken)
                        completion(success)
                    } else {
                        print("Unexpected response: \(json)")
                        completion(false)
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        task.resume()
    }
}
