//
//  UpdateChecker.swift
//  AnimeLounge
//
//  Created by Francesco on 09/08/24.
//

import Foundation
import UIKit

struct AppVersion: Codable {
    let version: String
    let buildNumber: Int
    let forceUpdate: Bool
    let updateMessage: String
    let releaseUrl: String
}

class UpdateChecker {
    static let shared = UpdateChecker()
    private let jsonURL = "https://raw.githubusercontent.com/cranci1/AnimeLounge/main/repo/versoin.json"
    
    func checkForUpdates(completion: @escaping (Bool, AppVersion?) -> Void) {
        guard let url = URL(string: jsonURL) else {
            completion(false, nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, nil)
                return
            }
            
            do {
                let remoteVersion = try JSONDecoder().decode(AppVersion.self, from: data)
                let updateAvailable = self.isUpdateAvailable(remoteVersion: remoteVersion)
                completion(updateAvailable, updateAvailable ? remoteVersion : nil)
            } catch {
                completion(false, nil)
            }
        }.resume()
    }
    
    private func isUpdateAvailable(remoteVersion: AppVersion) -> Bool {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
              let currentBuildNumber = Int(currentBuild) else {
            return false
        }
        
        if remoteVersion.version.compare(currentVersion, options: .numeric) == .orderedDescending {
            return true
        }
        
        if remoteVersion.version == currentVersion && remoteVersion.buildNumber > currentBuildNumber {
            return true
        }
        
        return false
    }
    
    func showUpdateAlert(appVersion: AppVersion) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Update Available",
                message: appVersion.updateMessage,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
                if let url = URL(string: appVersion.releaseUrl) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            
            if !appVersion.forceUpdate {
                alert.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: nil))
            }
            
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
