//
//  SettingsViewSources.swift
//  AnimeLounge
//
//  Created by Francesco on 03/08/24.
//

import UIKit


class SettingsViewSources: UITableViewController {
    
    @IBOutlet weak var retryMethod: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRetryMenu()
    }
    
    func setupRetryMenu() {
        let actions = [
            UIAction(title: "5 Tries", handler: { [weak self] _ in
                self?.setRetries(5)
            }),
            UIAction(title: "10 Tries", handler: { [weak self] _ in
                self?.setRetries(10)
            }),
            UIAction(title: "15 Tries", handler: { [weak self] _ in
                self?.setRetries(15)
            }),
            UIAction(title: "20 Tries", handler: { [weak self] _ in
                self?.setRetries(20)
            }),
            UIAction(title: "25 Tries", handler: { [weak self] _ in
                self?.setRetries(25)
            })
        ]
        
        let menu = UIMenu(title: "Select Retry Count", children: actions)
        
        retryMethod.menu = menu
        retryMethod.showsMenuAsPrimaryAction = true
        
        if let retries = UserDefaults.standard.value(forKey: "maxRetries") as? Int {
            retryMethod.setTitle("\(retries) Tries", for: .normal)
        } else {
            retryMethod.setTitle("Select Tries", for: .normal)
        }
    }
    
    private func setRetries(_ retries: Int) {
        UserDefaults.standard.set(retries, forKey: "maxRetries")
        retryMethod.setTitle("\(retries) Tries", for: .normal)
    }
}
