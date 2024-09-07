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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
    }
    
    private func loadUserDefaults() {
        introSwitch.isOn = UserDefaults.standard.bool(forKey: "autoSkipIntro")
        outroSwitch.isOn = UserDefaults.standard.bool(forKey: "autoSkipOutro")
        feedbacksSwitch.isOn = UserDefaults.standard.bool(forKey: "skipFeedbacks")
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
}
