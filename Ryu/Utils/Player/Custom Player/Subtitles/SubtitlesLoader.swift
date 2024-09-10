//
//  SubtitlesLoader.swift
//  Ryu
//
//  Created by Francesco on 25/08/24.
//

import Foundation
import AVFoundation

struct SubtitleCue {
    let startTime: CMTime
    let endTime: CMTime
    var originalText: String
    var translations: [String: String] = [:]
    
    mutating func setTranslation(_ text: String, for language: String) {
        translations[language] = text
    }
    
    func getTranslation(for language: String) -> String? {
        return translations[language]
    }
}

class SubtitlesLoader {
    static func parseVTT(data: Data, completion: @escaping ([SubtitleCue]) -> Void) {
        var cues: [SubtitleCue] = []
        let text = String(data: data, encoding: .utf8) ?? ""
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var currentCue: SubtitleCue?
        
        for line in lines {
            let lineStr = String(line)
            
            if lineStr.contains("-->") {
                let times = lineStr.components(separatedBy: " --> ")
                if times.count == 2 {
                    let startTime = timeToCMTime(timeString: times[0].trimmingCharacters(in: .whitespacesAndNewlines))
                    let endTime = timeToCMTime(timeString: times[1].trimmingCharacters(in: .whitespacesAndNewlines))
                    currentCue = SubtitleCue(startTime: startTime, endTime: endTime, originalText: "")
                }
            } else if !lineStr.isEmpty {
                currentCue?.originalText += removeHTMLTags(from: lineStr) + "\n"
            } else if let cue = currentCue {
                cues.append(cue)
                currentCue = nil
            }
        }
        
        completion(cues)
    }
    
    static func getTranslatedSubtitle(_ subtitle: SubtitleCue, completion: @escaping (SubtitleCue) -> Void) {
        let isTranslationEnabled = UserDefaults.standard.bool(forKey: "googleTranslation")
        let targetLanguage = UserDefaults.standard.string(forKey: "translationLanguage") ?? "en"
        
        if isTranslationEnabled {
            if let translatedText = subtitle.getTranslation(for: targetLanguage) {
                completion(subtitle)
            } else {
                var modifiedSubtitle = subtitle
                translateText(subtitle.originalText, targetLang: targetLanguage) { translatedText in
                    modifiedSubtitle.setTranslation(translatedText, for: targetLanguage)
                    completion(modifiedSubtitle)
                }
            }
        } else {
            completion(subtitle)
        }
    }
    
    private static func timeToCMTime(timeString: String) -> CMTime {
        let components = timeString.split(separator: ":")
        
        var hours: Double = 0
        var minutes: Double = 0
        var seconds: Double = 0
        var milliseconds: Double = 0
        
        switch components.count {
        case 3:
            hours = Double(components[0]) ?? 0
            minutes = Double(components[1]) ?? 0
            let secondsComponents = components[2].split(separator: ".")
            seconds = Double(secondsComponents[0]) ?? 0
            milliseconds = secondsComponents.count > 1 ? (Double(secondsComponents[1]) ?? 0) : 0
        case 2:
            minutes = Double(components[0]) ?? 0
            let secondsComponents = components[1].split(separator: ".")
            seconds = Double(secondsComponents[0]) ?? 0
            milliseconds = secondsComponents.count > 1 ? (Double(secondsComponents[1]) ?? 0) : 0
        case 1:
            let secondsComponents = components[0].split(separator: ".")
            seconds = Double(secondsComponents[0]) ?? 0
            milliseconds = secondsComponents.count > 1 ? (Double(secondsComponents[1]) ?? 0) : 0
        default:
            print("Invalid time format")
            return CMTime.zero
        }
        
        return CMTime(seconds: hours * 3600 + minutes * 60 + seconds + milliseconds / 1000, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    private static func removeHTMLTags(from text: String) -> String {
        let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "") ?? text
    }
    
    private static func translateText(_ text: String, targetLang: String, completion: @escaping (String) -> Void) {
        guard UserDefaults.standard.bool(forKey: "googleTranslation") else {
            completion(text)
            return
        }
        
        let url = URL(string: "https://translate-api-sable.vercel.app/api/translate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "text": text,
            "source_lang": "auto",
            "target_lang": targetLang
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                completion(text)
                return
            }
            
            guard let data = data else {
                print("No data received.")
                completion(text)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translatedText = json["data"] as? String {
                    completion(translatedText)
                } else {
                    completion(text)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(text)
            }
        }
        
        task.resume()
    }
}
