//
//  Kitsu+Token.swift
//  Ryu
//
//  Created by Francesco on 26/10/24.
//

import UIKit
import Security
import UserNotifications

class KitsuToken {
    static let clientID = "dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd"
    static let clientSecret = "54d7307928f63414defd96399fc31ba847961ceaecef3a5fd93144e960c0e151"
    
    static let tokenEndpoint = "https://kitsu.io/api/oauth/token"
    static let serviceName = "me.ryu.KitsuToken"
    static let accountName = "KitsuAccessToken"
    
    struct TokenResponse: Codable {
        let access_token: String
        let token_type: String
        let expires_in: Int
        let refresh_token: String
        let created_at: Int
    }
    
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
    
    static func scheduleTokenExpirationNotification(expiresIn: Int) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Kitsu Token Expiring"
                content.body = "Your Kitsu authentication token will expire soon. Please login again."
                content.sound = .default
                
                let triggerTime = TimeInterval(expiresIn - 86400)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
                
                let request = UNNotificationRequest(
                    identifier: "kitsu.token.expiration",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        }
    }
    
    static func authenticateUser(username: String, password: String, completion: @escaping (Bool) -> Void) {
        print("Authenticating Kitsu user...")
        
        guard let url = URL(string: tokenEndpoint) else {
            print("Invalid token endpoint URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "grant_type": "password",
            "username": username,
            "password": password,
            "client_id": clientID,
            "client_secret": clientSecret
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to create request body: \(error)")
            completion(false)
            return
        }
        
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
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                let success = saveTokenToKeychain(token: tokenResponse.access_token)
                
                if success {
                    scheduleTokenExpirationNotification(expiresIn: tokenResponse.expires_in)
                }
                
                completion(success)
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        task.resume()
    }
}
