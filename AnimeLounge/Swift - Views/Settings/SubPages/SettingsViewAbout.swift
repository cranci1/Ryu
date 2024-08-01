//
//  SettingsViewAbout.swift
//  AnimeLounge
//
//  Created by Francesco on 24/06/24.
//

import UIKit

class SettingsViewAbout: UITableViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var buildLabel: UILabel!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var licenseLabel: UILabel!
    
    let githubURL = "https://github.com/cranci1/AnimeLounge/"
    let reportIssueURL = "https://github.com/cranci1/AnimeLounge/issues"
    let reviewCodeURL = "https://github.com/cranci1/AnimeLounge/tree/main"
    let fullLicenseURL = "https://github.com/cranci1/AnimeLounge/blob/main/LICENSE"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "\(appVersion)"
        } else {
            versionLabel.text = "N/A"
        }
        
        if let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildLabel.text = "\(appBuild)"
        } else {
            buildLabel.text = "N/A"
        }
    }
    
    func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func githubTapped(_ sender: UITapGestureRecognizer) {
        openURL(githubURL)
    }
    
    @IBAction func reportIssueTapped(_ sender: UITapGestureRecognizer) {
        openURL(reportIssueURL)
    }
    
    @IBAction func reviewCodeTapped(_ sender: UITapGestureRecognizer) {
        openURL(reviewCodeURL)
    }
    
    @IBAction func fullLicenseTapped(_ sender: UITapGestureRecognizer) {
        openURL(fullLicenseURL)
    }
}
