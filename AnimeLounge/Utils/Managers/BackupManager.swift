//
//  BackupManager.swift
//  AnimeLounge
//
//  Created by Francesco on 01/07/24.
//

import Foundation

class BackupManager {
    static let shared = BackupManager()
    
    private init() {}
    
    func createBackup() -> String? {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        let serializable = dictionary.mapValues { value -> Any in
            if let data = value as? Data {
                return data.base64EncodedString()
            } else if let date = value as? Date {
                return date.iso8601String
            }
            return value
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: serializable, options: [])
            return data.base64EncodedString()
        } catch {
            print("Error creating backup: \(error)")
            return nil
        }
    }
    
    func importBackup(_ backupString: String) -> Bool {
        guard let data = Data(base64Encoded: backupString) else {
            print("Invalid backup string")
            return false
        }
        
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Invalid backup data")
                return false
            }
            
            let defaults = UserDefaults.standard
            for (key, value) in dictionary {
                if let stringValue = value as? String,
                   let data = Data(base64Encoded: stringValue) {
                    defaults.set(data, forKey: key)
                } else if let dateString = value as? String,
                          let date = Date.fromISO8601String(dateString) {
                    defaults.set(date, forKey: key)
                } else {
                    defaults.set(value, forKey: key)
                }
            }
            
            return true
        } catch {
            print("Error importing backup: \(error)")
            return false
        }
    }
}

extension Date {
    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    static func fromISO8601String(_ string: String) -> Date? {
        return ISO8601DateFormatter().date(from: string)
    }
}
