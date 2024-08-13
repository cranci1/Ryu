//
//  SettingsViewCast.swift
//  Ryu
//
//  Created by Francesco on 02/07/24.
//

import UIKit

class SettingsViewCast: UITableViewController {
    
    @IBOutlet var fullTitleSwitch: UISwitch!
    @IBOutlet var animeImageSwitch: UISwitch!
    
    @IBOutlet weak var castMethod: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
        setupMethodMenu()
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
    
    func setupMethodMenu() {
        let bufferedIcon = UIImage(systemName: "hourglass")
        let liveIcon = UIImage(systemName: "antenna.radiowaves.left.and.right")
        
        let action1 = UIAction(title: "buffered", image: bufferedIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("buffered", forKey: "castStreamingType")
            self?.castMethod.setTitle("buffered", for: .normal)
        })
        let action2 = UIAction(title: "live", image: liveIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("live", forKey: "castStreamingType")
            self?.castMethod.setTitle("live", for: .normal)
        })
        
        let menu = UIMenu(title: "Select Method", children: [action1, action2])
        
        castMethod.menu = menu
        castMethod.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "castStreamingType") {
            castMethod.setTitle(selectedOption, for: .normal)
        }
    }
}

