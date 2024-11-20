//
//  SettingsViewCast.swift
//  Ryu
//
//  Created by Francesco on 02/07/24.
//

import UIKit
import Network

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
    
    @IBAction func handleTapGesture() {
        requestLocalNetworkPermission()
    }
    
    func requestLocalNetworkPermission() {
        let loadingAlert = UIAlertController(title: "Requesting Permission", 
                                           message: "Please wait...", 
                                           preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        let parameters = NWParameters.udp
        let endpoint = NWEndpoint.hostPort(host: .ipv4(IPv4Address("224.0.0.1")!), port: 9999)
        let connection = NWConnection(to: endpoint, using: parameters)
        
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready, .setup:
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self?.showPermissionGrantedAlert()
                    }
                }
            case .failed(let error):
                print("Connection failed: \(error)")
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self?.showPermissionDeniedAlert()
                    }
                }
            case .waiting(let error):
                print("Connection waiting: \(error)")
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self?.showPermissionDeniedAlert()
                    }
                }
            default:
                break
            }
        }
        
        connection.start(queue: .main)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            connection.cancel()
        }
    }
    
    func showPermissionGrantedAlert() {
        let alertController = UIAlertController(title: "Permission Granted", message: "Local network access has been granted.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showPermissionDeniedAlert() {
        let alertController = UIAlertController(
            title: "Permission Required", 
            message: "Local network access is required for casting. Please go to Settings and enable local network access for this app.", 
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
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
