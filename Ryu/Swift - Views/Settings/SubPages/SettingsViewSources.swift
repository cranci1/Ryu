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
    
    @IBOutlet weak var gogoButton: UIButton!
    
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var serverButton: UIButton!
    @IBOutlet weak var subtitlesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRetryMenu()
        setupMenu()
        setupGoGo()
        setupAudioMenu()
        setupServerMenu()
        setupSubtitlesMenu()
        
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
    
    func setupGoGo() {
        let action1 = UIAction(title: "Default", handler: { [weak self] _ in
            UserDefaults.standard.set("Default", forKey: "gogoFetcher")
            self?.gogoButton.setTitle("Default", for: .normal)
        })
        let action2 = UIAction(title: "Secondary", handler: { [weak self] _ in
            UserDefaults.standard.set("Secondary", forKey: "gogoFetcher")
            self?.gogoButton.setTitle("Secondary", for: .normal)
        })
        
        let menu = UIMenu(title: "Select Prefered Method", children: [action1, action2])
        
        gogoButton.menu = menu
        gogoButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "gogoFetcher") {
            gogoButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    private func setRetries(_ retries: Int) {
        UserDefaults.standard.set(retries, forKey: "maxRetries")
        retryMethod.setTitle("\(retries) Tries", for: .normal)
    }
    
    func setupMenu() {
        let action1 = UIAction(title: "360p", handler: { [weak self] _ in
            UserDefaults.standard.set("360p", forKey: "preferredQuality")
            self?.qualityPrefered.setTitle("360p", for: .normal)
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
        let action1 = UIAction(title: "sub", handler: { [weak self] _ in
            UserDefaults.standard.set("sub", forKey: "audioHiPrefe")
            self?.audioButton.setTitle("sub", for: .normal)
        })
        let action2 = UIAction(title: "dub", handler: { [weak self] _ in
            UserDefaults.standard.set("dub", forKey: "audioHiPrefe")
            self?.audioButton.setTitle("dub", for: .normal)
        })
        let action3 = UIAction(title: "raw", handler: { [weak self] _ in
            UserDefaults.standard.set("raw", forKey: "audioHiPrefe")
            self?.audioButton.setTitle("raw", for: .normal)
        })
        let action4 = UIAction(title: "Always Ask", handler: { [weak self] _ in
            UserDefaults.standard.set("Always Ask", forKey: "audioHiPrefe")
            self?.audioButton.setTitle("Always Ask", for: .normal)
        })
        
        let menu = UIMenu(title: "Select Prefered Audio", children: [action1, action2, action3, action4])
        
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
        let action3 = UIAction(title: "Always Ask", handler: { [weak self] _ in
            UserDefaults.standard.set("Always Ask", forKey: "serverHiPrefe")
            self?.serverButton.setTitle("Always Ask", for: .normal)
        })
        
        let menu = UIMenu(title: "Select Prefered Server", children: [action1, action2, action3])
        
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
        let action2 = UIAction(title: "Always Ask", handler: { [weak self] _ in
            UserDefaults.standard.set("Always Ask", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("Always Ask", for: .normal)
        })
        let action3 = UIAction(title: "No Subtitles", handler: { [weak self] _ in
            UserDefaults.standard.set("No Subtitles", forKey: "subtitleHiPrefe")
            self?.subtitlesButton.setTitle("No Subtitles", for: .normal)
        })
        
        let menu = UIMenu(title: "Select Subtitles Language", children: [action1, action3, action2])
        
        subtitlesButton.menu = menu
        subtitlesButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "subtitleHiPrefe") {
            subtitlesButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
