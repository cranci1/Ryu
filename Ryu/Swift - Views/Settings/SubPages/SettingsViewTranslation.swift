//
//  SettingsViewTranslation.swift
//  Ryu
//
//  Created by Francesco on 10/09/24.
//

import UIKit

class SettingsViewTranslation: UITableViewController {
    
    @IBOutlet var translationSwitch: UISwitch!
    @IBOutlet var selfhostSwitch: UISwitch!
    
    @IBOutlet weak var preferedLanguage: UIButton!
    
    private var viewModel = LocalServerViewModel()
    private var progressAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
        setupLanguageMenu()
        setupViewModel()
    }
    
    private func loadUserDefaults() {
        translationSwitch.isOn = UserDefaults.standard.bool(forKey: "googleTranslation")
        selfhostSwitch.isOn = UserDefaults.standard.bool(forKey: "selfHostEnabled")
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func translationToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "googleTranslation")
    }
    
    func setupLanguageMenu() {
        let currentLanguage = UserDefaults.standard.string(forKey: "translationLanguage")
        
        let languageOptions: [(String, String)] = [
            ("ar", "Arabic"),
            ("bg", "Bulgarian"),
            ("cs", "Czech"),
            ("da", "Danish"),
            ("de", "German"),
            ("el", "Greek"),
            ("es", "Spanish"),
            ("et", "Estonian"),
            ("fi", "Finnish"),
            ("fr", "French"),
            ("hu", "Hungarian"),
            ("id", "Indonesian"),
            ("it", "Italian"),
            ("ja", "Japanese"),
            ("ko", "Korean"),
            ("lt", "Lithuanian"),
            ("lv", "Latvian"),
            ("nl", "Dutch"),
            ("pl", "Polish"),
            ("pt", "Portuguese"),
            ("ro", "Romanian"),
            ("ru", "Russian"),
            ("sk", "Slovak"),
            ("sl", "Slovenian"),
            ("sv", "Swedish"),
            ("tr", "Turkish"),
            ("uk", "Ukrainian")
        ]
        
        let languageItems = languageOptions.map { (code, name) in
            UIAction(title: name, state: currentLanguage == code ? .on : .off) { [weak self] _ in
                UserDefaults.standard.set(code, forKey: "translationLanguage")
                self?.preferedLanguage.setTitle(name, for: .normal)
            }
        }
        
        let languageSubmenu = UIMenu(title: "Select the Language", children: languageItems)
        
        preferedLanguage.menu = languageSubmenu
        preferedLanguage.showsMenuAsPrimaryAction = true
        
        if let selectedLanguageCode = UserDefaults.standard.string(forKey: "translationLanguage"),
           let selectedLanguageName = languageOptions.first(where: { $0.0 == selectedLanguageCode })?.1 {
            preferedLanguage.setTitle(selectedLanguageName, for: .normal)
        } else {
            preferedLanguage.setTitle("English", for: .normal)
        }
    }
    
    @IBAction func selfSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "selfHostEnabled")
        
        if sender.isOn {
            startSelfHostingServer()
        }
    }
    
    private func startSelfHostingServer() {
        showProgressAlert()
        viewModel.selectedRepository = viewModel.repository
        viewModel.startProcess()
    }

    private func showProgressAlert() {
        progressAlert = UIAlertController(title: "Starting Self-Host", message: "Initializing...", preferredStyle: .alert)
        if let alert = progressAlert {
            present(alert, animated: true)
        }
    }

    private func updateProgressAlert(message: String) {
        progressAlert?.message = message
    }

    private func setupViewModel() {
        viewModel.onUpdate = { [weak self] statusMessage in
            DispatchQueue.main.async {
                self?.updateProgressAlert(message: statusMessage)
            }
        }
        
        viewModel.onProcessFinished = { [weak self] in
            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.dismissProgressAlert()
                }
            }
        }
    }

    private func dismissProgressAlert() {
        if let alert = progressAlert {
            alert.dismiss(animated: true, completion: nil)
            progressAlert = nil
        }
    }
}
