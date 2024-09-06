//
//  AppDelegate.swift
//  Ryu
//
//  Created by Francesco on 20/06/24.
//

import UIKit
import GoogleCast
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var backgroundCompletionHandler: (() -> Void)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupDefaultUserPreferences()
        setupGoogleCast()
        
        return true
    }
    
    private func setupDefaultUserPreferences() {
        if UserDefaults.standard.object(forKey: "selectedMediaSource") == nil {
            UserDefaults.standard.set("AnimeWorld", forKey: "selectedMediaSource")
        }
        
        if UserDefaults.standard.object(forKey: "AnimeListingService") == nil {
            UserDefaults.standard.set("AniList", forKey: "AnimeListingService")
        }
        
        if UserDefaults.standard.object(forKey: "maxRetries") == nil {
            UserDefaults.standard.set(10, forKey: "maxRetries")
        }
        
        if UserDefaults.standard.object(forKey: "holdSpeedPlayer") == nil {
            UserDefaults.standard.set(2, forKey: "holdSpeedPlayer")
        }
        
        if UserDefaults.standard.object(forKey: "preferredQuality") == nil {
            UserDefaults.standard.set("1080p", forKey: "preferredQuality")
        }
        
        if UserDefaults.standard.object(forKey: "hideWebPlayer") == nil {
            UserDefaults.standard.set(true, forKey: "hideWebPlayer")
        }
        
        if UserDefaults.standard.object(forKey: "subtitleHiPrefe") == nil {
            UserDefaults.standard.set("English", forKey: "subtitleHiPrefe")
        }
        
        if UserDefaults.standard.object(forKey: "serverHiPrefe") == nil {
            UserDefaults.standard.set("hd-1", forKey: "serverHiPrefe")
        }
        
        if UserDefaults.standard.object(forKey: "audioHiPrefe") == nil {
            UserDefaults.standard.set("dub", forKey: "audioHiPrefe")
        }
        
        if (UserDefaults.standard.object(forKey: "accessToken") != nil) {
            UserDefaults.standard.removeObject(forKey: "accessToken")
        }
        
        UserDefaults.standard.register(defaults: ["fullTitleCast": true])
        UserDefaults.standard.register(defaults: ["animeImageCast": true])
    }
    
    private func setupGoogleCast() {
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "ryu" {
            if let queryParams = url.queryParameters, let code = queryParams["code"] {
                NotificationCenter.default.post(name: Notification.Name("AuthorizationCodeReceived"), object: nil, userInfo: ["code": code])
            }
        }
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.set(false, forKey: "isToDownload")
        deleteTemporaryDirectory()
    }
    
    func deleteTemporaryDirectory() {
        let fileManager = FileManager.default
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        do {
            let tmpContents = try fileManager.contentsOfDirectory(at: tmpURL, includingPropertiesForKeys: nil, options: [])
            
            for fileURL in tmpContents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing tmp folder: \(error.localizedDescription)")
        }
    }
}
