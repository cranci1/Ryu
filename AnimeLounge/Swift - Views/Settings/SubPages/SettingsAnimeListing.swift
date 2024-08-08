//
//  SettingsAnimeListing.swift
//  AnimeLounge
//
//  Created by Francesco on 27/07/24.
//

import UIKit

class SettingsAnimeListing: UITableViewController {
    
    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUserStatus()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthorizationCode(_:)), name: Notification.Name("AuthorizationCodeReceived"), object: nil)
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startAuthenticationTapped() {
        AniListLogin.authenticate()
    }
    
    @objc func handleAuthorizationCode(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let code = userInfo["code"] as? String else {
            print("Failed to retrieve authorization code")
            return
        }
        print("Authorization code received: \(code)")
        AniListToken.exchangeAuthorizationCodeForToken(code: code)
    }
    
    func updateUserStatus() {
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            fetchUserInfo(token: token)
        } else {
            statusLabel.text = "You are not loggede in"
        }
    }
    
    func fetchUserInfo(token: String) {
        let userInfoURL = URL(string: "https://graphql.anilist.co")!
        var request = URLRequest(url: userInfoURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let query = """
        {
            Viewer {
                id
                name
                options {
                    profileColor
                }
            }
        }
        """

        let body: [String: Any] = ["query": query]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            DispatchQueue.main.async {
                self.statusLabel.text = "Failed to serialize JSON: \(error.localizedDescription)"
            }
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "No data received"
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any],
                   let viewer = dict["data"] as? [String: Any],
                   let user = viewer["Viewer"] as? [String: Any],
                   let username = user["name"] as? String,
                   let options = user["options"] as? [String: Any],
                   let profileColorName = options["profileColor"] as? String {
                    
                    let color = self.colorFromName(profileColorName)
                    
                    DispatchQueue.main.async {
                        let fullText = "Logged in as \(username)"
                        let attributedText = NSMutableAttributedString(string: fullText)
                        
                        let usernameRange = (fullText as NSString).range(of: username)
                        attributedText.addAttribute(.foregroundColor, value: color, range: usernameRange)
                        
                        self.statusLabel.attributedText = attributedText
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Unexpected response format"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Failed to parse JSON: \(error.localizedDescription)"
                }
            }
        }

        task.resume()
    }
    
    func colorFromName(_ name: String) -> UIColor {
        switch name.lowercased() {
        case "blue":
            return UIColor.systemBlue
        case "purple":
            return UIColor.systemPurple
        case "pink":
            return UIColor.systemPink
        case "orange":
            return UIColor.systemOrange
        case "red":
            return UIColor.systemRed
        case "green":
            return UIColor.systemGreen
        case "gray":
            return UIColor.systemGray
        case "teal":
            return UIColor.systemTeal
        case "yellow":
            return UIColor.systemYellow
        default:
            return UIColor.label
        }
    }
}
