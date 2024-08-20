//
//  SettingsAnimeListing.swift
//  Ryu
//
//  Created by Francesco on 27/07/24.
//

import UIKit
import Security

class SettingsAnimeListing: UITableViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loginLogoutLabel: UILabel!
    
    let serviceName = "me.ryu.AniListToken"
    let accountName = "AniListAccessToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserStatus()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(loginLogoutLabelTapped))
        loginLogoutLabel.isUserInteractionEnabled = true
        loginLogoutLabel.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthorizationCode(_:)), name: Notification.Name("AuthorizationCodeReceived"), object: nil)
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func loginLogoutLabelTapped() {
        if let _ = getTokenFromKeychain() {
            showLogoutConfirmation()
        } else {
            statusLabel.text = "Starting authentication..."
            AniListLogin.authenticate()
        }
    }
    
    func showLogoutConfirmation() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.logout()
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func logout() {
        removeTokenFromKeychain()
        statusLabel.text = "You are not logged in"
        updateLoginLogoutLabelText()
    }
    
    @objc func handleAuthorizationCode(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let code = userInfo["code"] as? String else {
            print("Failed to retrieve authorization code")
            return
        }
        print("Authorization code received: \(code)")
        updateStatusForTokenExchange()
        AniListToken.exchangeAuthorizationCodeForToken(code: code) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.statusLabel.text = "Login successful! Updating user info..."
                    self?.updateUserStatus()
                } else {
                    self?.statusLabel.text = "Login failed. Please try again."
                }
            }
        }
    }
    
    func updateStatusForTokenExchange() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Exchanging code for token..."
        }
    }
    
    func updateUserStatus() {
        if let token = getTokenFromKeychain() {
            fetchUserInfo(token: token)
        } else {
            statusLabel.text = "You are not logged in"
        }
        updateLoginLogoutLabelText()
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
        case "green":
            return UIColor.systemGreen
        case "orange":
            return UIColor.systemOrange
        case "red":
            return UIColor.systemRed
        case "pink":
            return UIColor.systemPink
        case "gray":
            return UIColor.systemGray
        default:
            return UIColor.label
        }
    }
    
    func updateLoginLogoutLabelText() {
        let isLoggedIn = getTokenFromKeychain() != nil
        let labelText = isLoggedIn ? "Log Out from AniList.co" : "Log In with AniList.co"
        loginLogoutLabel.text = labelText
    }
    
    func getTokenFromKeychain() -> String? {
         let query: [String: Any] = [
             kSecClass as String: kSecClassGenericPassword,
             kSecAttrService as String: serviceName,
             kSecAttrAccount as String: accountName,
             kSecReturnData as String: kCFBooleanTrue!,
             kSecMatchLimit as String: kSecMatchLimitOne
         ]
         
         var item: CFTypeRef?
         let status = SecItemCopyMatching(query as CFDictionary, &item)
         
         guard status == errSecSuccess, let tokenData = item as? Data else {
             return nil
         }
         
         return String(data: tokenData, encoding: .utf8)
     }

     func removeTokenFromKeychain() {
         let deleteQuery: [String: Any] = [
             kSecClass as String: kSecClassGenericPassword,
             kSecAttrService as String: serviceName,
             kSecAttrAccount as String: accountName
         ]
         SecItemDelete(deleteQuery as CFDictionary)
     }
 }
