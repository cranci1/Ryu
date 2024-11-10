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
    var style: String?
    
    mutating func setTranslation(_ text: String, for language: String) {
        translations[language] = text
    }
    
    func getTranslation(for language: String) -> String? {
        return translations[language]
    }
}

enum SubtitleFormat {
    case vtt
    case srt
    case ass
    
    static func detect(from text: String) -> SubtitleFormat {
        if text.lowercased().contains("webvtt") {
            return .vtt
        } else if text.lowercased().contains("[script info]") {
            return .ass
        } else {
            return .srt
        }
    }
}

class SubtitlesLoader {
    static func parseSubtitles(data: Data, format: SubtitleFormat? = nil, completion: @escaping ([SubtitleCue]) -> Void) {
        guard let text = String(data: data, encoding: .utf8) else {
            completion([])
            return
        }
        
        let detectedFormat = format ?? SubtitleFormat.detect(from: text)
        
        switch detectedFormat {
        case .vtt:
            parseVTT(text: text, completion: completion)
        case .srt:
            parseSRT(text: text, completion: completion)
        case .ass:
            parseASS(text: text, completion: completion)
        }
    }
    
    static func parseVTT(text: String, completion: @escaping ([SubtitleCue]) -> Void) {
        var cues: [SubtitleCue] = []
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
            } else if !lineStr.isEmpty && currentCue != nil {
                var cue = currentCue!
                cue.originalText += removeHTMLTags(from: lineStr) + "\n"
                currentCue = cue
            } else if let cue = currentCue {
                cues.append(cue)
                currentCue = nil
            }
        }
        
        if let lastCue = currentCue {
            cues.append(lastCue)
        }
        
        completion(cues)
    }
    
    static func parseSRT(text: String, completion: @escaping ([SubtitleCue]) -> Void) {
        var cues: [SubtitleCue] = []
        let blocks = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        
        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard lines.count >= 3 else { continue }
            
            let timeLine = lines[1]
            let textLines = Array(lines[2...])
            
            let timeComponents = timeLine.components(separatedBy: " --> ")
            guard timeComponents.count == 2 else { continue }
            
            let startTime = srtTimeToCMTime(timeString: timeComponents[0].trimmingCharacters(in: .whitespacesAndNewlines))
            let endTime = srtTimeToCMTime(timeString: timeComponents[1].trimmingCharacters(in: .whitespacesAndNewlines))
            
            let text = textLines.joined(separator: "\n")
            let cue = SubtitleCue(startTime: startTime, endTime: endTime, originalText: removeHTMLTags(from: text))
            cues.append(cue)
        }
        
        completion(cues)
    }
    
    static func parseASS(text: String, completion: @escaping ([SubtitleCue]) -> Void) {
        var cues: [SubtitleCue] = []
        var inEventsSection = false
        var formatLine: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.starts(with: "[Events]") {
                inEventsSection = true
                continue
            }
            
            if inEventsSection {
                if trimmedLine.starts(with: "Format:") {
                    formatLine = trimmedLine.replacingOccurrences(of: "Format:", with: "")
                        .split(separator: ",")
                        .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                } else if trimmedLine.starts(with: "Dialogue:") {
                    let dialogueComponents = trimmedLine.replacingOccurrences(of: "Dialogue:", with: "")
                        .split(separator: ",", maxSplits: formatLine.count - 1, omittingEmptySubsequences: false)
                        .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    
                    guard dialogueComponents.count >= 9 else { continue }
                    
                    let startTime = assTimeToCMTime(timeString: dialogueComponents[1])
                    let endTime = assTimeToCMTime(timeString: dialogueComponents[2])
                    let style = dialogueComponents[3]
                    let text = dialogueComponents[9...].joined(separator: ",")
                    
                    var cue = SubtitleCue(startTime: startTime, endTime: endTime, originalText: removeASSFormatting(from: text))
                    cue.style = style
                    cues.append(cue)
                }
            }
        }
        
        completion(cues)
    }
    
    static func getTranslatedSubtitle(_ subtitle: SubtitleCue, completion: @escaping (SubtitleCue) -> Void) {
        let isTranslationEnabled = UserDefaults.standard.bool(forKey: "googleTranslation")
        let targetLanguage = UserDefaults.standard.string(forKey: "translationLanguage") ?? "en"
        
        if isTranslationEnabled {
            if subtitle.getTranslation(for: targetLanguage) != nil {
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
        
        let customURLString = UserDefaults.standard.string(forKey: "savedTranslatorInstance")
        let urlString = customURLString ?? "https://translate-api-first.vercel.app/api/translate"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(text)
            return
        }
        
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

extension SubtitlesLoader {
    private static func srtTimeToCMTime(timeString: String) -> CMTime {
        let components = timeString.components(separatedBy: ":")
        guard components.count == 3 else { return .zero }
        
        let hours = Double(components[0]) ?? 0
        let minutes = Double(components[1]) ?? 0
        
        let secondsAndMillis = components[2].components(separatedBy: ",")
        let seconds = Double(secondsAndMillis[0]) ?? 0
        let milliseconds = Double(secondsAndMillis.count > 1 ? secondsAndMillis[1] : "0") ?? 0
        
        return CMTime(seconds: hours * 3600 + minutes * 60 + seconds + milliseconds / 1000,
                      preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    private static func assTimeToCMTime(timeString: String) -> CMTime {
        let components = timeString.split(separator: ":")
        guard components.count == 3 else { return .zero }
        
        let hours = Double(components[0]) ?? 0
        let minutes = Double(components[1]) ?? 0
        let seconds = Double(components[2]) ?? 0
        
        return CMTime(seconds: hours * 3600 + minutes * 60 + seconds,
                      preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    private static func removeASSFormatting(from text: String) -> String {
        var cleanText = text.replacingOccurrences(of: "\\{[^}]*\\}", with: "", options: .regularExpression)
        
        let assTagsPattern = "\\\\[Nn]|\\\\[Hh]|\\\\[Bb]\\d|\\\\[Ii]\\d|\\\\[Ss]\\d|\\\\[Uu]\\d|\\\\[Aa]\\d"
        cleanText = cleanText.replacingOccurrences(of: assTagsPattern, with: "", options: .regularExpression)
        
        return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
