//
//  SettingsViewTranslation.swift
//  Ryu
//
//  Created by Francesco on 10/09/24.
//

import UIKit

class SettingsViewTranslation: UITableViewController {
    
    @IBOutlet var translationSwitch: UISwitch!
    @IBOutlet var customInstanceSwitch: UISwitch!
    
    @IBOutlet weak var preferedLanguage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
        setupLanguageMenu()
    }
    
    private func loadUserDefaults() {
        translationSwitch.isOn = UserDefaults.standard.bool(forKey: "googleTranslation")
        customInstanceSwitch.isOn = UserDefaults.standard.bool(forKey: "customTranslatorInstance")
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
    
    @IBAction func urlToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "customTranslatorInstance")
        
        if sender.isOn {
            presentURLAlert()
        }
    }
    
    private func presentURLAlert() {
        let alertController = UIAlertController(title: "Enter custom Instance URL", message: "Make sure to follow the rules in the footer of the cell", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "https://translate-api-first.vercel.app/api/translate"
            textField.keyboardType = .URL
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let urlString = alertController.textFields?.first?.text {
                self?.saveURL(urlString)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.customInstanceSwitch.setOn(false, animated: true)
            UserDefaults.standard.set(false, forKey: "customTranslatorInstance")
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveURL(_ urlString: String) {
        UserDefaults.standard.set(urlString, forKey: "savedTranslatorInstance")
    }
}
