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
    var text: String
}

class SubtitlesLoader {
    static func parseVTT(data: Data, completion: @escaping ([SubtitleCue]) -> Void) {
        var cues: [SubtitleCue] = []
        let text = String(data: data, encoding: .utf8) ?? ""
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var currentCue: SubtitleCue?
        
        let isTranslationEnabled = UserDefaults.standard.bool(forKey: "googleTranslation")
        let targetLanguage = UserDefaults.standard.string(forKey: "translationLanguage") ?? "en"
        
        let dispatchGroup = DispatchGroup()
        
        for line in lines {
            let lineStr = String(line)
            
            if lineStr.contains("-->") {
                let times = lineStr.components(separatedBy: " --> ")
                if times.count == 2 {
                    let startTime = timeToCMTime(timeString: times[0].trimmingCharacters(in: .whitespacesAndNewlines))
                    let endTime = timeToCMTime(timeString: times[1].trimmingCharacters(in: .whitespacesAndNewlines))
                    currentCue = SubtitleCue(startTime: startTime, endTime: endTime, text: "")
                }
            } else if !lineStr.isEmpty {
                currentCue?.text += removeHTMLTags(from: lineStr) + "\n"
            } else if let cue = currentCue {
                if isTranslationEnabled {
                    dispatchGroup.enter()
                    translateText(cue.text, targetLang: targetLanguage) { translatedText in
                        var translatedCue = cue
                        translatedCue.text = translatedText
                        cues.append(translatedCue)
                        dispatchGroup.leave()
                    }
                } else {
                    cues.append(cue)
                }
                currentCue = nil
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(cues)
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
