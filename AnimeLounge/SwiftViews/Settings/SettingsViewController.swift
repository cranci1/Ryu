//
//  SettingsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet var autoPlaySwitch: UISwitch!
    @IBOutlet var landScapeSwitch: UISwitch!
    @IBOutlet var browserPlayerSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autoPlaySwitch.isOn = UserDefaults.standard.bool(forKey: "AutoPlay")
        landScapeSwitch.isOn = UserDefaults.standard.bool(forKey: "AlwaysLandscape")
        browserPlayerSwitch.isOn = UserDefaults.standard.bool(forKey: "browserPlayer")
    }
    
    @IBAction func clearCache(_ sender: Any) {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        
        do {
            if let cacheURL = cacheURL {
                let filePaths = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil, options: [])
                for filePath in filePaths {
                    try FileManager.default.removeItem(at: filePath)
                }
                showAlert(message: "Cache cleared successfully!")
            }
        } catch {
            print("Could not clear cache: \(error)")
            showAlert(message: "Failed to clear cache.")
        }
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func autpPlayToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AutoPlay")
    }
    
    @IBAction func landScapeToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AlwaysLandscape")
    }
    
    @IBAction func browserPlayerToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "browserPlayer")
    }
}
