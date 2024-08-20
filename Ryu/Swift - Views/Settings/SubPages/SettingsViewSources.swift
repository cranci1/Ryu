//
//  SettingsViewSources.swift
//  Ryu
//
//  Created by Francesco on 03/08/24.
//

import UIKit


class SettingsViewSources: UITableViewController {
    
    @IBOutlet weak var retryMethod: UIButton!
    @IBOutlet weak var qualityPrefered: UIButton!
    
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var serverButton: UIButton!
    @IBOutlet weak var subtitlesButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRetryMenu()
        setupMenu()
        setupAudioMenu()
        setupServerMenu()
        setupSubtitlesMenu()
        setupHideMenu()
        
        if let selectedOption = UserDefaults.standard.string(forKey: "preferredQuality") {
            qualityPrefered.setTitle(selectedOption, for: .normal)
        }
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
    
    func setupMenu() {
        let action1 = UIAction(title: "320p", handler: { [weak self] _ in
            UserDefaults.standard.set("320p", forKey: "preferredQuality")
            self?.qualityPrefered.setTitle("320p", for: .normal)
        })
        let action2 = UIAction(title: "480p", handler: { [weak self] _ in
            UserDefaults.standard.set("480p", forKey: "preferredQuality")
            self?.qualityPrefered.setTitle("480p", for: .normal)
        })
        let action3 = UIAction(title: "720p", handler: { [weak self] _ in
            UserDefaults.standard.set("720p", forKey: "preferredQuality")
            self?.qualityPrefered.setTitle("720p", for: .normal)
        })
        let action4 = UIAction(title: "1080p", handler: { [weak self] _ in
            UserDefaults.standard.set("1080p", forKey: "preferredQuality")
            self?.qualityPrefered.setTitle("1080p", for: .normal)
        })

        let menu = UIMenu(title: "Select Prefered Quality", children: [action1, action2, action3, action4])
        
        qualityPrefered.menu = menu
        qualityPrefered.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "preferredQuality") {
            qualityPrefered.setTitle(selectedOption, for: .normal)
        }
    }
    
    func setupAudioMenu() {
        let action1 = UIAction(title: "Sub", handler: { [weak self] _ in
            UserDefaults.standard.set("sub", forKey: "audioHiPrefe")
            self?.audioButton.setTitle("Sub", for: .normal)
        })
        let action2 = UIAction(title: "Dub", handler: { [weak self] _ in
            UserDefaults.standard.set("dub", forKey: "audioHiPrefe")
            self?.audioButton.setTitle("Dub", for: .normal)
        })

        let menu = UIMenu(title: "Select Prefered Audio", children: [action1, action2])
        
        audioButton.menu = menu
        audioButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "audioHiPrefe") {
            audioButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    func setupServerMenu() {
        let action1 = UIAction(title: "hd-1", handler: { [weak self] _ in
            UserDefaults.standard.set("hd-1", forKey: "serverHiPrefe")
            self?.serverButton.setTitle("hd-1", for: .normal)
        })
        let action2 = UIAction(title: "hd-2", handler: { [weak self] _ in
            UserDefaults.standard.set("hd-2", forKey: "serverHiPrefe")
            self?.serverButton.setTitle("hd-2", for: .normal)
        })

        let menu = UIMenu(title: "Select Prefered Server", children: [action1, action2])
        
        serverButton.menu = menu
        serverButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "serverHiPrefe") {
            serverButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    func setupSubtitlesMenu() {
        let action1 = UIAction(title: "English", handler: { [weak self] _ in
            UserDefaults.standard.set("English", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("English", for: .normal)
        })
        let action2 = UIAction(title: "Spanish", handler: { [weak self] _ in
            UserDefaults.standard.set("Spanish", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("Spanish", for: .normal)
        })
        let action3 = UIAction(title: "Portuguese", handler: { [weak self] _ in
            UserDefaults.standard.set("Portuguese", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("Portuguese", for: .normal)
        })
        let action4 = UIAction(title: "Thai", handler: { [weak self] _ in
            UserDefaults.standard.set("Thai", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("Thai", for: .normal)
        })
        let action5 = UIAction(title: "French", handler: { [weak self] _ in
            UserDefaults.standard.set("French", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("French", for: .normal)
        })
        let action6 = UIAction(title: "Always Ask", handler: { [weak self] _ in
            UserDefaults.standard.set("Always Ask", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("Always Ask", for: .normal)
        })

        let menu = UIMenu(title: "Select Captions Language", children: [action1, action2, action3, action4, action5, action6])
        
        subtitlesButton.menu = menu
        subtitlesButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "subtitleHiPrefe") {
            subtitlesButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    func setupHideMenu() {
        let action1 = UIAction(title: "Yes", handler: { [weak self] _ in
            UserDefaults.standard.set(true, forKey: "hideWebPlayer")
            self?.hideButton.setTitle("Yes", for: .normal)
        })
        let action2 = UIAction(title: "No", handler: { [weak self] _ in
            UserDefaults.standard.set(false, forKey: "hideWebPlayer")
            self?.hideButton.setTitle("No", for: .normal)
        })
        
        let menu = UIMenu(title: "Hide the webplayer?", children: [action1, action2])
        
        hideButton.menu = menu
        hideButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.value(forKey: "hideWebPlayer") as? Bool {
            hideButton.setTitle(selectedOption ? "Yes" : "No", for: .normal)
        }
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
