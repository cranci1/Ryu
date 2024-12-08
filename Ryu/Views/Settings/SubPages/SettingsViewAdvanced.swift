//
//  SettingsViewAdvanced.swift
//  Ryu
//
//  Created by Francesco on 08/12/24.
//

import UIKit

class SettingsViewAdvanced: UITableViewController {

    @IBOutlet weak var proxyIPButton: UIButton!
    @IBOutlet weak var proxyPortButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateButtonTitles()
        setupMenus()
    }

    @IBAction func proxyIPButtonTapped(_ sender: UIButton) {
        showPopupMenu(for: "ProxyIP", sender: sender)
    }

    @IBAction func proxyPortButtonTapped(_ sender: UIButton) {
        showPopupMenu(for: "ProxyPort", sender: sender)
    }

    private func showPopupMenu(for key: String, sender: UIButton) {
        let menu = createMenu(for: key)
        sender.menu = menu
        sender.showsMenuAsPrimaryAction = true
    }

    private func createMenu(for key: String) -> UIMenu {
        let noneAction = UIAction(title: "None", handler: { _ in
            UserDefaults.standard.set(nil, forKey: key)
            self.updateButtonTitles()
        })
        
        let customAction = UIAction(title: "Custom", handler: { _ in
            self.showCustomAlert(for: key)
        })
        
        return UIMenu(title: "Select Option", children: [noneAction, customAction])
    }

    private func showCustomAlert(for key: String) {
        let alert = UIAlertController(title: "Enter Custom Value", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = key == "ProxyIP" ? "Enter Proxy IP" : "Enter Proxy Port"
            textField.keyboardType = key == "ProxyIP" ? .default : .numberPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let textField = alert.textFields?.first, let text = textField.text, !text.isEmpty {
                UserDefaults.standard.set(text, forKey: key)
                self.updateButtonTitles()
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    private func updateButtonTitles() {
        let proxyIP = UserDefaults.standard.string(forKey: "ProxyIP") ?? "None"
        let proxyPort = UserDefaults.standard.string(forKey: "ProxyPort") ?? "None"
        proxyIPButton.setTitle(proxyIP, for: .normal)
        proxyPortButton.setTitle(proxyPort, for: .normal)
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupMenus() {
        proxyIPButton.menu = createMenu(for: "ProxyIP")
        proxyPortButton.menu = createMenu(for: "ProxyPort")
        proxyIPButton.showsMenuAsPrimaryAction = true
        proxyPortButton.showsMenuAsPrimaryAction = true
    }
}
