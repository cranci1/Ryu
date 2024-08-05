//
//  AppDelegate.swift
//  AnimeLounge
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
        setupAudioSession()
        setupDefaultUserPreferences()
        setupGoogleCast()
        
        return true
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
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
        
        UserDefaults.standard.register(defaults: ["fullTitleCast": true])
        UserDefaults.standard.register(defaults: ["animeImageCast": true])
    }
    
    private func setupGoogleCast() {
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
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
    }
}
