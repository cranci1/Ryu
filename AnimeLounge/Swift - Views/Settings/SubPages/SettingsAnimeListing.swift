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
            statusLabel.text = "User not logged in"
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
                siteUrl
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
                   let username = user["name"] as? String {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Logged in as \(username)"
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
}
