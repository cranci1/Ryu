//
//  SettingsViewCast.swift
//  AnimeLounge
//
//  Created by Francesco on 02/07/24.
//

import UIKit

class SettingsViewCast: UITableViewController {
    
    @IBOutlet var fullTitleSwitch: UISwitch!
    @IBOutlet var animeImageSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
    }
    
    private func loadUserDefaults() {
        fullTitleSwitch.isOn = UserDefaults.standard.bool(forKey: "fullTitleCast")
        animeImageSwitch.isOn = UserDefaults.standard.bool(forKey: "animeImageCast")
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func fullTitleToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "fullTitleCast")
    }
    
    @IBAction func animeImageToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "animeImageCast")
    }
}

