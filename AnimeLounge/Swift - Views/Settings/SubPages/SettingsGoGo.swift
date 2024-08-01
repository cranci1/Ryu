//
//  SettingsGoGo.swift
//  AnimeLounge
//
//  Created by Francesco on 13/07/24.
//

import UIKit


class SettingsGoGo: UITableViewController {
    
    @IBOutlet weak var methodGoGoButton: UIButton!
    // @IBOutlet weak var methodJKButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGoGoMenu()
        // setupJKMenu()
    }
    
    func setupGoGoMenu() {
        let expeIcon = UIImage(systemName: "bolt.fill")
        let defaultIcon = UIImage(systemName: "checkmark.circle.fill")
        
        let action1 = UIAction(title: "Experimental", image: expeIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Experimental", forKey: "GoGoAnimeMethod")
            self?.methodGoGoButton.setTitle("Experimental", for: .normal)
        })
        let action2 = UIAction(title: "Stable", image: defaultIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Stable", forKey: "GoGoAnimeMethod")
            self?.methodGoGoButton.setTitle("Stable", for: .normal)
        })
        
        let menu = UIMenu(title: "Select Method", children: [action1, action2])
        
        methodGoGoButton.menu = menu
        methodGoGoButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "GoGoAnimeMethod") {
            methodGoGoButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    // func setupJKMenu() {
    //    let expeIcon = UIImage(systemName: "bolt.fill")
    //    let defaultIcon = UIImage(systemName: "checkmark.circle.fill")
    //
    //    let action1 = UIAction(title: "Experimental", image: expeIcon, handler: { [weak self] _ in
    //        UserDefaults.standard.set("Experimental", forKey: "JKAnimeMethod")
    //        self?.methodJKButton.setTitle("Experimental", for: .normal)
    //    })
    //    let action2 = UIAction(title: "Stable", image: defaultIcon, handler: { [weak self] _ in
    //        UserDefaults.standard.set("Stable", forKey: "JKAnimeMethod")
    //        self?.methodJKButton.setTitle("Stable", for: .normal)
    //    })
    //
    //    let menu = UIMenu(title: "Select Method", children: [action1, action2])
    //
    //    methodJKButton.menu = menu
    //    methodJKButton.showsMenuAsPrimaryAction = true
    //
    //    if let selectedOption = UserDefaults.standard.string(forKey: "JKAnimeMethod") {
    //        methodJKButton.setTitle(selectedOption, for: .normal)
    //    }
    // }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
