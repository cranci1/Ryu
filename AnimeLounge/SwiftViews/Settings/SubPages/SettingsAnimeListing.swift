//
//  SettingsAnimeListing.swift
//  AnimeLounge
//
//  Created by Francesco on 27/07/24.
//

import UIKit

class SettingsAnimeListing: UITableViewController {

    @IBOutlet weak var aniListSwitch: UISwitch!
    @IBOutlet weak var malSwitch: UISwitch!
    @IBOutlet weak var kitsuSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectedService = UserDefaults.standard.string(forKey: "AnimeListingService")
        
        aniListSwitch.isOn = (selectedService == "AniList")
        malSwitch.isOn = (selectedService == "MAL")
        kitsuSwitch.isOn = (selectedService == "Kitsu")
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender == aniListSwitch {
            if aniListSwitch.isOn {
                UserDefaults.standard.set("AniList", forKey: "AnimeListingService")
                malSwitch.setOn(false, animated: true)
                kitsuSwitch.setOn(false, animated: true)
            }
        } else if sender == malSwitch {
            if malSwitch.isOn {
                UserDefaults.standard.set("MAL", forKey: "AnimeListingService")
                aniListSwitch.setOn(false, animated: true)
                kitsuSwitch.setOn(false, animated: true)
            }
        } else if sender == kitsuSwitch {
            if kitsuSwitch.isOn {
                UserDefaults.standard.set("Kitsu", forKey: "AnimeListingService")
                aniListSwitch.setOn(false, animated: true)
                malSwitch.setOn(false, animated: true)
            }
        }
    }
}
