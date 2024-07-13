//
//  SettingsGoGo.swift
//  AnimeLounge
//
//  Created by Francesco on 13/07/24.
//

import UIKit


class SettingsGoGo: UITableViewController {
    
    @IBOutlet weak var methodButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMenu()
    }
    
    func setupMenu() {
        let defaultIcon = UIImage(systemName: "play.rectangle.fill")
        let videoIcon = UIImage(systemName: "play.circle.fill")

        let action1 = UIAction(title: "Experimental", image: defaultIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Experimental", forKey: "GoGoAnimeMethod")
            self?.methodButton.setTitle("Experimental", for: .normal)
        })
        let action2 = UIAction(title: "Stable", image: videoIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Stable", forKey: "GoGoAnimeMethod")
            self?.methodButton.setTitle("Stable", for: .normal)
        })

        let menu = UIMenu(title: "Select Method", children: [action1, action2])
        
        methodButton.menu = menu
        methodButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "GoGoAnimeMethod") {
            methodButton.setTitle(selectedOption, for: .normal)
        }
    }
}
