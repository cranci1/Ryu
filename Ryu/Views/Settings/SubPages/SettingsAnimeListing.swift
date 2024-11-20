//
//  SettingsAnimeListing.swift
//  Ryu
//
//  Created by Francesco on 27/07/24.
//

import UIKit
import Security

class SettingsAnimeListing: UITableViewController {
    
    @IBOutlet weak var anilistStatusLabel: UILabel!
    @IBOutlet weak var anilistLoginLogoutLabel: UILabel!
    @IBOutlet weak var kitsuStatusLabel: UILabel!
    @IBOutlet weak var kitsuLoginLogoutLabel: UILabel!
    
    @IBOutlet var pushUpdatesSwitch: UISwitch!
    
    let anilistServiceName = "me.ryu.AniListToken"
    let anilistAccountName = "AniListAccessToken"
    let kitsuServiceName = "me.ryu.KitsuToken"
    let kitsuAccountName = "KitsuAccessToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pushUpdatesSwitch.isEnabled = false
        
        updateUserStatus()
        loadUserDefaultss()
        
        let anilistTapGesture = UITapGestureRecognizer(target: self, action: #selector(loginLogoutLabelTapped))
        anilistLoginLogoutLabel.isUserInteractionEnabled = true
        anilistLoginLogoutLabel.addGestureRecognizer(anilistTapGesture)
        
        let kitsuTapGesture = UITapGestureRecognizer(target: self, action: #selector(kitsuLoginLogoutLabelTapped))
        kitsuLoginLogoutLabel.isUserInteractionEnabled = true
        kitsuLoginLogoutLabel.addGestureRecognizer(kitsuTapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthorizationCode(_:)), name: Notification.Name("AuthorizationCodeReceived"), object: nil)
        updateKitsuUserStatus()
    }
    
    func loadUserDefaultss() {
        pushUpdatesSwitch.isOn = UserDefaults.standard.bool(forKey: "sendPushUpdates")
    }
    
    @IBAction func pushUpdatesToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "sendPushUpdates")
    }
    
    @IBAction func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func loginLogoutLabelTapped() {
        if let _ = getTokenFromKeychain() {
            showLogoutConfirmation()
        } else {
            anilistStatusLabel.text = "Starting authentication..."
            AniListLogin.authenticate()
        }
    }
    
    func showLogoutConfirmation() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out from AniList?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.logout()
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func logout() {
        removeTokenFromKeychain()
        anilistStatusLabel.text = "You are not logged in"
        updateLoginLogoutLabelText()
    }
    
    @objc func handleAuthorizationCode(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let code = userInfo["code"] as? String else {
                  print("Failed to retrieve authorization code")
                  return
              }
        updateStatusForTokenExchange()
        AniListToken.exchangeAuthorizationCodeForToken(code: code) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.anilistStatusLabel.text = "Login successful! Updating user info..."
                    self?.updateUserStatus()
                } else {
                    self?.anilistStatusLabel.text = "Login failed. Please try again."
                }
            }
        }
    }
    
    func updateStatusForTokenExchange() {
        DispatchQueue.main.async {
            self.anilistStatusLabel.text = "Exchanging code for token..."
        }
    }
    
    func updateUserStatus() {
        if let token = getTokenFromKeychain() {
            pushUpdatesSwitch.isEnabled = true
            fetchUserInfo(token: token)
        } else {
            anilistStatusLabel.text = "You are not logged in"
            pushUpdatesSwitch.isEnabled = false
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
                self.anilistStatusLabel.text = "Failed to serialize JSON: \(error.localizedDescription)"
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.anilistStatusLabel.text = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.anilistStatusLabel.text = "No data received"
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
                        
                        self.anilistStatusLabel.attributedText = attributedText
                        self.pushUpdatesSwitch.isEnabled = true
                        self.loadUserDefaultss()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.anilistStatusLabel.text = "Unexpected response format"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.anilistStatusLabel.text = "Failed to parse JSON: \(error.localizedDescription)"
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
        anilistLoginLogoutLabel.text = labelText
    }
    
    func getTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: anilistServiceName,
            kSecAttrAccount as String: anilistAccountName,
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
            kSecAttrService as String: anilistServiceName,
            kSecAttrAccount as String: anilistAccountName
        ]
        SecItemDelete(deleteQuery as CFDictionary)
    }
    
    @objc func kitsuLoginLogoutLabelTapped() {
        if let _ = getKitsuTokenFromKeychain() {
            showKitsuLogoutConfirmation()
        } else {
            showKitsuLoginPrompt()
        }
    }
    
    func showKitsuLoginPrompt() {
        let alert = UIAlertController(title: "Login to Kitsu", message: "Enter your email/username and password", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Email or Username"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Login", style: .default) { [weak self] _ in
            guard let username = alert.textFields?[0].text,
                  let password = alert.textFields?[1].text,
                  !username.isEmpty, !password.isEmpty else {
                      self?.kitsuStatusLabel.text = "Please enter both username and password"
                      return
                  }
            
            self?.kitsuStatusLabel.text = "Logging in..."
            
            KitsuToken.authenticateUser(username: username, password: password) { success in
                DispatchQueue.main.async {
                    if success {
                        self?.kitsuStatusLabel.text = "Login successful! Updating user info..."
                        self?.updateKitsuUserStatus()
                    } else {
                        self?.kitsuStatusLabel.text = "Login failed. Please try again."
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    func showKitsuLogoutConfirmation() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out from Kitsu?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.kitsuLogout()
        })
        
        present(alert, animated: true)
    }
    
    func kitsuLogout() {
        removeKitsuTokenFromKeychain()
        kitsuStatusLabel.text = "You are not logged in"
        updateKitsuLoginLogoutLabelText()
    }
    
    func updateKitsuUserStatus() {
        if let token = getKitsuTokenFromKeychain() {
            fetchKitsuUserInfo(token: token)
        } else {
            kitsuStatusLabel.text = "You are not logged in"
        }
        updateKitsuLoginLogoutLabelText()
    }
    
    func fetchKitsuUserInfo(token: String) {
        let userInfoURL = URL(string: "https://kitsu.io/api/edge/users?filter[self]=true")!
        var request = URLRequest(url: userInfoURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.kitsuStatusLabel.text = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.kitsuStatusLabel.text = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let data = json["data"] as? [[String: Any]],
                       let firstUser = data.first,
                       let attributes = firstUser["attributes"] as? [String: Any],
                       let username = attributes["name"] as? String {
                        
                        self?.kitsuStatusLabel.text = "Logged in as \(username)"
                    } else {
                        self?.kitsuStatusLabel.text = "Failed to parse user info"
                    }
                } catch {
                    self?.kitsuStatusLabel.text = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    func updateKitsuLoginLogoutLabelText() {
        let isLoggedIn = getKitsuTokenFromKeychain() != nil
        kitsuLoginLogoutLabel.text = isLoggedIn ? "Log Out from Kitsu" : "Log In with Kitsu"
    }
    
    func getKitsuTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: kitsuServiceName,
            kSecAttrAccount as String: kitsuAccountName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let tokenData = item as? Data else {
                  return nil
              }
        
        return String(data: tokenData, encoding: .utf8)
    }
    
    func removeKitsuTokenFromKeychain() {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: kitsuServiceName,
            kSecAttrAccount as String: kitsuAccountName
        ]
        SecItemDelete(deleteQuery as CFDictionary)
    }
}
