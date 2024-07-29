//
//  SettingsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import UniformTypeIdentifiers

class SettingsViewController: UITableViewController {
    
    @IBOutlet var notificationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func loadUserDefaults() {
        notificationSwitch.isOn = UserDefaults.standard.bool(forKey: "notificationOnDownload")
    }
    
    @IBAction func notificationToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "notificationOnDownload")
        if sender.isOn {
            requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.notificationSwitch.isOn = false
                    UserDefaults.standard.set(false, forKey: "notificationOnDownload")
                }
                return
            }
            
            DispatchQueue.main.async {
                if !granted {
                    self.notificationSwitch.isOn = false
                    UserDefaults.standard.set(false, forKey: "notificationOnDownload")
                }
            }
        }
    }
}
