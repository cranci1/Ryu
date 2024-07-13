//
//  SettingsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class SettingsViewController: UITableViewController {

    @IBOutlet var autoPlaySwitch: UISwitch!
    @IBOutlet var landScapeSwitch: UISwitch!
    @IBOutlet var browserPlayerSwitch: UISwitch!
    
    @IBOutlet weak var playerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
        setupMenu()
    }
    
    func setupMenu() {
        let defaultIcon = UIImage(systemName: "play.rectangle.fill")
        let infuseIcon = UIImage(systemName: "flame")
        let vlcIcon = UIImage(systemName: "film")
        let outIcon = UIImage(systemName: "play.circle.fill")

        let action1 = UIAction(title: "Default", image: defaultIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Default", forKey: "mediaPlayerSelected")
            self?.playerButton.setTitle("Default", for: .normal)
        })
        let action2 = UIAction(title: "VLC", image: vlcIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("VLC", forKey: "mediaPlayerSelected")
            self?.playerButton.setTitle("VLC", for: .normal)
        })
        let action3 = UIAction(title: "Infuse", image: infuseIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Infuse", forKey: "mediaPlayerSelected")
            self?.playerButton.setTitle("Infuse", for: .normal)
        })
        let action4 = UIAction(title: "Outplayer", image: outIcon, handler: { [weak self] _ in
            UserDefaults.standard.set("Outplayer", forKey: "mediaPlayerSelected")
            self?.playerButton.setTitle("Outplayer", for: .normal)
        })

        let menu = UIMenu(title: "Select Media Player", children: [action1, action2, action3, action4])
        
        playerButton.menu = menu
        playerButton.showsMenuAsPrimaryAction = true
        
        if let selectedOption = UserDefaults.standard.string(forKey: "mediaPlayerSelected") {
            playerButton.setTitle(selectedOption, for: .normal)
        }
    }
    
    private func loadUserDefaults() {
        autoPlaySwitch.isOn = UserDefaults.standard.bool(forKey: "AutoPlay")
        landScapeSwitch.isOn = UserDefaults.standard.bool(forKey: "AlwaysLandscape")
        browserPlayerSwitch.isOn = UserDefaults.standard.bool(forKey: "browserPlayer")
    }
    
    @IBAction func clearCache(_ sender: Any) {
        clearCache()
    }
    
    @IBAction func autpPlayToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AutoPlay")
    }
    
    @IBAction func landScapeToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AlwaysLandscape")
    }
    
    @IBAction func browserPlayerToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "browserPlayer")
    }
    
    @IBAction func createBackup(_ sender: Any) {
        guard let backupString = BackupManager.shared.createBackup() else {
            showAlert(message: "Failed to create backup.")
            return
        }
        saveBackupToTemporaryDirectory(backupString, sender: sender)
    }
    
    @IBAction private func importBackupTapped(_ sender: Any) {
        presentDocumentPicker()
    }
    
    @IBAction private func resetAppTapped(_ sender: Any) {
        presentResetConfirmation()
    }
    
    @IBAction func clearSearchHistory(_ sender: Any) {
        clearSearchHistory()
    }
    
    private func clearSearchHistory() {
        UserDefaults.standard.removeObject(forKey: "SearchHistory")
        showAlert(message: "Search history cleared successfully!")
    }
    
    private func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        
        do {
            if let cacheURL = cacheURL {
                let filePaths = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil, options: [])
                for filePath in filePaths {
                    try FileManager.default.removeItem(at: filePath)
                }
                showAlert(message: "Cache cleared successfully!")
            }
        } catch {
            print("Could not clear cache: \(error)")
            showAlert(message: "Failed to clear cache.")
        }
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveBackupToTemporaryDirectory(_ backupString: String, sender: Any) {
        let backupData = Data(backupString.utf8)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd_MMMM_yyyy-HHmm"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "\(dateString).albackup"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try backupData.write(to: tempURL)
            presentActivityViewController(with: tempURL, sender: sender)
        } catch {
            showAlert(message: "Failed to save backup: \(error.localizedDescription)")
        }
    }
    
    private func presentActivityViewController(with url: URL, sender: Any) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact, .markupAsPDF]
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sender as? UIView ?? view
            popoverController.sourceRect = (sender as? UIView)?.bounds ?? view.bounds
        }
        
        present(activityVC, animated: true, completion: nil)
    }
    
    private func presentDocumentPicker() {
        let documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType("me.cranci.albackup")!], asCopy: true)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["me.cranci.albackup"], in: .import)
        }
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func presentResetConfirmation() {
        let alertController = UIAlertController(title: "Reset App Settings", message: "Are you sure you want to reset all app settings? This action cannot be undone.", preferredStyle: .alert)
        
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.resetUserDefaults()
            self?.loadUserDefaults()
            self?.showAlert(message: "App settings have been reset.")
        }
        
        alertController.addAction(resetAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func resetUserDefaults() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
    }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            showAlert(message: "No file selected.")
            return
        }
        
        importBackup(from: selectedFileURL)
    }
    
    private func importBackup(from url: URL) {
        do {
            let backupData = try Data(contentsOf: url)
            guard let backupString = String(data: backupData, encoding: .utf8) else {
                showAlert(message: "Invalid backup file format.")
                return
            }
            
            if BackupManager.shared.importBackup(backupString) {
                showAlert(message: "Backup imported successfully!")
                loadUserDefaults()
            } else {
                showAlert(message: "Failed to import backup.")
            }
        } catch {
            showAlert(message: "Failed to read backup file: \(error.localizedDescription)")
        }
    }
}
