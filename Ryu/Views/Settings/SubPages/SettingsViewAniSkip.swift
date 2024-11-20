//
//  SettingsViewAniSkip.swift
//  Ryu
//
//  Created by Francesco on 07/09/24.
//

import UIKit

class SettingsViewAniSkip: UITableViewController {
    
    @IBOutlet var introSwitch: UISwitch!
    @IBOutlet var outroSwitch: UISwitch!
    @IBOutlet var feedbacksSwitch: UISwitch!
    @IBOutlet var urlSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
    }
    
    private func loadUserDefaults() {
        introSwitch.isOn = UserDefaults.standard.bool(forKey: "autoSkipIntro")
        outroSwitch.isOn = UserDefaults.standard.bool(forKey: "autoSkipOutro")
        feedbacksSwitch.isOn = UserDefaults.standard.bool(forKey: "skipFeedbacks")
        urlSwitch.isOn = UserDefaults.standard.bool(forKey: "customAnimeSkipInstance")
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func introToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "autoSkipIntro")
    }
    
    @IBAction func outroToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "autoSkipOutro")
    }
    
    @IBAction func feedbacksToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "skipFeedbacks")
    }
    
    @IBAction func urlToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "customAnimeSkipInstance")
        
        if sender.isOn {
            presentURLAlert()
        }
    }
    
    private func presentURLAlert() {
        let alertController = UIAlertController(title: "Enter custom Instance URL", message: "Make sure to follow the rules in the footer of the cell", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "https://api.aniskip.com/"
            textField.keyboardType = .URL
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let urlString = alertController.textFields?.first?.text {
                self?.saveURL(urlString)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.urlSwitch.setOn(false, animated: true)
            UserDefaults.standard.set(false, forKey: "customAnimeSkipInstance")
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveURL(_ urlString: String) {
        UserDefaults.standard.set(urlString, forKey: "savedAniSkipInstance")
    }
}
