//
//  AnimeDetailService.swift
//  Ryu
//
//  Created by Francesco on 25/06/24.
//

import Alamofire
import SwiftSoup
import UIKit

struct AnimeDetail {
    let aliases: String
    let synopsis: String
    let airdate: String
    let stars: String
    let episodes: [Episode]
}

class AnimeDetailService {
    static func fetchAnimeDetails(from href: String, completion: @escaping (Result<AnimeDetail, Error>) -> Void) {
        guard let selectedSource = UserDefaults.standard.selectedMediaSource else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No media source selected."])))
            return
        }
        
        let baseUrls: [String]
        switch selectedSource {
        case .animeWorld:
            baseUrls = ["https://animeworld.so"]
        case .gogoanime:
            baseUrls = ["https://anitaku.pe"]
        case .animeheaven:
            baseUrls = ["https://animeheaven.me/"]
        case .hianime:
            baseUrls = [
                "https://aniwatch-api-dusky.vercel.app/anime/info?id=",
                "https://aniwatch-api-cranci.vercel.app/anime/info?id="
            ]
        case .anilibria:
            baseUrls = ["https://api.anilibria.tv/v3/title?id="]
        case .animefire, .kuramanime, .jkanime, .anime3rb, .hanashi, .animesrbija, .aniworld:
            baseUrls = [""]
        }
        
        let baseUrl = baseUrls.randomElement()!
        let fullUrl: String
        
        if selectedSource == .anilibria,
           href.hasPrefix("https://cache.libria.fun/videos/media/ts/") {
            let components = href.components(separatedBy: "/")
            if let tsIndex = components.firstIndex(of: "ts"),
               tsIndex + 1 < components.count,
               let extractedId = components[tsIndex + 1].components(separatedBy: CharacterSet.decimalDigits.inverted).first {
                fullUrl = baseUrl + extractedId
            } else {
                fullUrl = baseUrl + href
            }
        } else {
            fullUrl = baseUrl + href
        }
        
        if selectedSource == .anilibria {
            AF.request(fullUrl).responseDecodable(of: AnilibriaResponse.self) { response in
                switch response.result {
                case .success(let anilibriaResponse):
                    let aliases = anilibriaResponse.names.en
                    let synopsis = anilibriaResponse.description
                    let airdate = "\(anilibriaResponse.season.year) \(anilibriaResponse.season.string)"
                    let stars = ""
                    
                    let episodes = anilibriaResponse.player.list.map { (key, value) -> Episode in
                        let episodeNumber = key
                        
                        let fhdUrl = value.hls.fhd.map { "https://cache.libria.fun\($0)" }
                        let hdUrl = value.hls.hd.map { "https://cache.libria.fun\($0)" }
                        let sdUrl = value.hls.sd.map { "https://cache.libria.fun\($0)" }
                        
                        let selectedUrl = fhdUrl ?? hdUrl ?? sdUrl ?? ""
                        
                        return Episode(number: episodeNumber, href: selectedUrl, downloadUrl: "")
                    }.sorted { Int($0.number) ?? 0 < Int($1.number) ?? 0 }
                    
                    let details = AnimeDetail(aliases: aliases, synopsis: synopsis, airdate: airdate, stars: stars, episodes: episodes)
                    completion(.success(details))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else if selectedSource == .hianime {
            let prefixes = [
                "https://aniwatch-api-dusky.vercel.app/anime/episode-srcs?id=",
                "https://aniwatch-api-cranci.vercel.app/anime/episode-srcs?id="
            ]
            
            func extractIdentifier(from fullUrl: String) -> String? {
                for prefix in prefixes {
                    if let idRange = fullUrl.range(of: prefix) {
                        let startIndex = fullUrl.index(idRange.upperBound, offsetBy: 0)
                        if let endRange = fullUrl[startIndex...].range(of: "?ep=") ?? fullUrl[startIndex...].range(of: "&ep=") {
                            let identifier = String(fullUrl[startIndex..<endRange.lowerBound])
                            return identifier
                        }
                    }
                }
                return nil
            }
            
            let fullUrl: String
            if href.contains("https") {
                if let identifier = extractIdentifier(from: href) {
                    fullUrl = baseUrl + identifier
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL format."])))
                    return
                }
            } else {
                fullUrl = baseUrl + href
            }
            
            AF.request(fullUrl).responseJSON { response in
                switch response.result {
                case .success(let json):
                    guard
                        let jsonDict = json as? [String: Any],
                        let animeInfo = jsonDict["anime"] as? [String: Any],
                        let moreInfo = animeInfo["moreInfo"] as? [String: Any] else {
                            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format."])))
                            return
                        }
                    
                    let description = (animeInfo["info"] as? [String: Any])?["description"] as? String ?? ""
                    let name = (animeInfo["info"] as? [String: Any])?["name"] as? String ?? ""
                    let premiered = moreInfo["premiered"] as? String ?? ""
                    let malscore = moreInfo["malscore"] as? String ?? ""
                    
                    let aliases = name
                    let airdate = premiered
                    let stars = malscore
                    
                    fetchHiAnimeEpisodes(from: href) { result in
                        switch result {
                        case .success(let episodes):
                            let details = AnimeDetail(aliases: aliases, synopsis: description, airdate: airdate, stars: stars, episodes: episodes)
                            completion(.success(details))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            AF.request(fullUrl).responseString { response in
                switch response.result {
                case .success(let html):
                    do {
                        let document = try SwiftSoup.parse(html)
                        let aliases: String
                        let synopsis: String
                        let airdate: String
                        let stars: String
                        let episodes: [Episode]
                        
                        switch selectedSource {
                        case .animeWorld:
                            aliases = try document.select("div.widget-title h1").attr("data-jtitle")
                            synopsis = try document.select("div.info div.desc").text()
                            airdate = try document.select("div.row dl.meta dt:contains(Data di Uscita) + dd").first()?.text() ?? ""
                            stars = try document.select("dd.rating span").text()
                        case .gogoanime:
                            aliases = try document.select("div.anime_info_body_bg p.other-name a").text()
                            synopsis = try document.select("div.anime_info_body_bg div.description").text()
                            airdate = try document.select("p.type:contains(Released:)").first()?.text().replacingOccurrences(of: "Released: ", with: "") ?? ""
                            stars = ""
                        case .animeheaven:
                            aliases = try document.select("div.infodiv div.infotitlejp").text()
                            synopsis = try document.select("div.infodiv div.infodes").text()
                            airdate = try document.select("div.infoyear div.c2").eq(1).text()
                            stars = try document.select("div.infoyear div.c2").last()?.text() ?? ""
                        case .animefire:
                            aliases = try document.select("div.mr-2 h6.text-gray").text()
                            synopsis = try document.select("div.divSinopse span.spanAnimeInfo").text()
                            airdate = try document.select("div.divAnimePageInfo div.animeInfo span.spanAnimeInfo").last()?.text() ?? ""
                            stars = try document.select("div.div_anime_score h4.text-white").text()
                        case .kuramanime:
                            aliases = try document.select("div.anime__details__title span").last()?.text() ?? ""
                            synopsis = try document.select("div.anime__details__text p").text()
                            airdate = try document.select("div.anime__details__widget ul li div.col-9").eq(3).text()
                            stars = try document.select("div.anime__details__widget div.row div.col-lg-6 ul li").select("div:contains(Skor:) ~ div.col-9").text()
                        case .jkanime:
                            aliases = try document.select("div.anime__details__title span").text()
                            synopsis = try document.select("p.tab.sinopsis").text()
                            airdate = try document.select("li:contains(Emitido:)").first()?.text().replacingOccurrences(of: "Emitido: ", with: "") ?? ""
                            stars = ""
                        case .anime3rb:
                            aliases = ""
                            synopsis = try document.select("p.leading-loose").text()
                            airdate = try document.select("td[title]").attr("title")
                            stars = try document.select("p.text-lg.leading-relaxed").first()?.text() ?? ""
                        case .hianime:
                            aliases = ""
                            synopsis = ""
                            airdate = ""
                            stars = ""
                        case .hanashi:
                            aliases = ""
                            synopsis = ""
                            airdate = ""
                            stars = ""
                        case .anilibria:
                            aliases = ""
                            synopsis = ""
                            airdate = ""
                            stars = ""
                        case .animesrbija:
                            aliases = try document.select("h3.anime-eng-name").text()
                            
                            let rawSynopsis = try document.select("div.anime-description").text()
                            synopsis = rawSynopsis.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                            
                            if let dateElement = try document.select("div.anime-information-col div:contains(Datum:)").first()?.text(),
                               let dateStr = dateElement.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
                                airdate = dateStr.components(separatedBy: "to")
                                    .first?
                                    .trimmingCharacters(in: .whitespaces) ?? ""
                            } else {
                                airdate = ""
                            }
                            
                            if let scoreElement = try document.select("div.anime-information-col div:contains(MAL Ocena:)").first()?.text(),
                               let scoreStr = scoreElement.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
                                stars = scoreStr
                            } else {
                                stars = ""
                            }
                        case .aniworld:
                            aliases = ""
                            synopsis = try document.select("p.seri_des").text()
                            airdate = "N/A"
                            stars = "N/A"
                        }
                        
                        episodes = self.fetchEpisodes(document: document, for: selectedSource, href: href)
                        
                        let details = AnimeDetail(aliases: aliases, synopsis: synopsis, airdate: airdate, stars: stars, episodes: episodes)
                        completion(.success(details))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func fetchHiAnimeEpisodes(from href: String, completion: @escaping (Result<[Episode], Error>) -> Void) {
        let baseUrl = "https://aniwatch-api-dusky.vercel.app/anime/episodes/"
        
        let fullUrl: String
        if href.contains("https") {
            guard let idRange = href.range(of: "id="),
                  let endRange = href.range(of: "?ep=") ?? href.range(of: "&ep=") else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid href format."])))
                return
            }
            
            let startIndex = idRange.upperBound
            let endIndex = endRange.lowerBound
            let id = String(href[startIndex..<endIndex])
            
            fullUrl = baseUrl + id
        } else {
            fullUrl = baseUrl + href
        }
        
        AF.request(fullUrl).responseJSON { response in
            switch response.result {
            case .success(let json):
                guard
                    let jsonDict = json as? [String: Any],
                    let episodesArray = jsonDict["episodes"] as? [[String: Any]]
                else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format."])))
                    return
                }
                
                let episodes = episodesArray.compactMap { episodeDict -> Episode? in
                    guard
                        let episodeId = episodeDict["episodeId"] as? String,
                        let number = episodeDict["number"] as? Int
                    else {
                        return nil
                    }
                    
                    let episodeNumber = "\(number)"
                    let hrefID = episodeId
                    let href = "https://aniwatch-api-dusky.vercel.app/anime/episode-srcs?id=" + hrefID
                    
                    return Episode(number: episodeNumber, href: href, downloadUrl: "")
                }
                
                completion(.success(episodes))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private static func fetchEpisodes(document: Document, for source: MediaSource, href: String) -> [Episode] {
        var episodes: [Episode] = []
        do {
            var episodeElements: Elements
            var downloadUrlElement: String
            
            switch source {
            case .animeWorld:
                episodeElements = try document.select("div.server.active ul.episodes li.episode a")
                downloadUrlElement = ""
            case .gogoanime:
                episodeElements = try document.select("ul#episode_page a")
                downloadUrlElement = ""
            case .animeheaven:
                episodeElements = try document.select("a[href^='episode.php']")
                downloadUrlElement = ""
            case .animefire:
                episodeElements = try document.select("div.div_video_list a")
                downloadUrlElement = ""
            case .kuramanime:
                let episodeContent = try document.select("div#episodeListsSection a.follow-btn").attr("data-content")
                let episodeDocument = try SwiftSoup.parse(episodeContent)
                episodeElements = try episodeDocument.select("a.btn")
                downloadUrlElement = ""
            case .jkanime:
                episodeElements = try document.select("div.anime__pagination a.numbers")
                downloadUrlElement = ""
            case .anime3rb:
                episodeElements = try document.select("div.absolute.overflow-hidden div a.gap-3")
                downloadUrlElement = ""
            case .hianime:
                episodeElements = try document.select("")
                downloadUrlElement = ""
            case .hanashi:
                episodeElements = try document.select("")
                downloadUrlElement = ""
            case .anilibria:
                episodeElements = try document.select("")
                downloadUrlElement = ""
            case .animesrbija:
                 episodeElements = try document.select("ul.anime-episodes-holder li.anime-episode-item")
                 downloadUrlElement = ""
            case .aniworld:
                episodeElements = try document.select("table.seasonEpisodesList tbody tr")
                downloadUrlElement = ""
            }
            
            switch source {
            case .gogoanime:
                episodeElements = try document.select("ul#episode_page a")
                downloadUrlElement = ""
                episodes = episodeElements.flatMap { element -> [Episode] in
                    guard let startStr = try? element.attr("ep_start"),
                          let endStr = try? element.attr("ep_end"),
                          let start = Int(startStr),
                          let end = Int(endStr) else { return [] }
                    
                    let validStart = min(start, end)
                    let validEnd = max(start, end)
                    
                    return (validStart...validEnd).map { episodeNumber in
                        let formattedEpisode = "\(episodeNumber)"
                        let episodeHref = "\(href)-episode-\(episodeNumber)"
                        let downloadUrl = try? document.select(downloadUrlElement).attr("href")
                        
                        return Episode(number: formattedEpisode, href: episodeHref, downloadUrl: downloadUrl ?? "")
                    }
                    .filter { $0.number != "0" }
                }
            case .animeheaven:
                episodes = episodeElements.compactMap { element in
                    do {
                        let episodeNumber = try element.select("div.watch2.bc").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        let episodeHref = try element.attr("href")
                        
                        guard let episodeNumber = episodeNumber else { return nil }
                        return Episode(number: episodeNumber, href: episodeHref, downloadUrl: "")
                    } catch {
                        print("Error parsing AnimeHeaven episode: \(error.localizedDescription)")
                        return nil
                    }
                }
            case .animefire:
                var filmCount = 0
                episodes = episodeElements.compactMap { element in
                    do {
                        let episodeTitle = try element.text()
                        let href = try element.attr("href")
                        
                        if episodeTitle.contains("Filme") {
                            filmCount += 1
                            let episodeNumber = "\(filmCount)"
                            return Episode(number: episodeNumber, href: href, downloadUrl: "")
                        }
                        
                        let episodeNumber = episodeTitle.components(separatedBy: "Episódio ")
                            .last?.components(separatedBy: " - ").first?.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let episodeNumber = episodeNumber {
                            return Episode(number: episodeNumber, href: href, downloadUrl: "")
                        }
                    } catch {
                        print("Error parsing AnimeFire episode: \(error.localizedDescription)")
                    }
                    return nil
                }
            case .kuramanime:
                do {
                    let episodeContent = try document.select("div#episodeListsSection a.follow-btn").attr("data-content")
                    let episodeDocument = try SwiftSoup.parse(episodeContent)
                    episodeElements = try episodeDocument.select("a.btn")
                    
                    episodes = try episodeElements.compactMap { element in
                        let episodeText = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        let href = try element.attr("href")
                        
                        let episodeNumber = episodeText.replacingOccurrences(of: "Ep ", with: "")
                        
                        guard !episodeNumber.isEmpty, Int(episodeNumber) != nil else {
                            print("Invalid episode number: \(episodeText)")
                            return nil
                        }
                        
                        return Episode(number: episodeNumber, href: href, downloadUrl: "")
                    }
                } catch {
                    print("Error parsing Kuramanime episodes: \(error.localizedDescription)")
                }
            case .jkanime:
                episodes = episodeElements.flatMap { element -> [Episode] in
                    guard let episodeText = try? element.text() else { return [] }
                    
                    let parts = episodeText.split(separator: "-")
                    guard parts.count == 2,
                          let start = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                          let end = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
                              return []
                          }
                    
                    return (max(1, start)...end).map { episodeNumber in
                        let formattedEpisode = String(episodeNumber)
                        let episodeHref = "\(href)\(String(format: "%02d", episodeNumber))"
                        
                        return Episode(number: formattedEpisode, href: episodeHref, downloadUrl: "")
                    }
                }
            case .anime3rb:
                episodes = episodeElements.compactMap { element in
                    do {
                        let episodeTitle = try element.select("div.video-metadata span").first()?.text() ?? ""
                        let episodeNumber = episodeTitle.replacingOccurrences(of: "الحلقة ", with: "")
                        let href = try element.attr("href")
                        
                        return Episode(number: episodeNumber, href: href, downloadUrl: "")
                    } catch {
                        print("Error parsing Anime3rb episode: \(error.localizedDescription)")
                        return nil
                    }
                }
            case .animesrbija:
                episodes = try episodeElements.compactMap { element in
                    let episodeNumber = try element.select("span.anime-episode-num").text()
                        .replacingOccurrences(of: "Epizoda ", with: "")
                    let hrefBase = try element.select("a.anime-episode-link").attr("href")
                    let href = "https://www.animesrbija.com" + hrefBase
                    
                    return Episode(number: episodeNumber, href: href, downloadUrl: "")
                }
                episodes.sort {
                    if let num1 = Int($0.number), let num2 = Int($1.number) {
                        return num1 < num2
                    }
                    return false
                }
            case .aniworld:
                episodes = episodeElements.compactMap { element in
                    do {
                        let episodeNumber = try element.select("td.season3EpisodeID meta[itemprop=episodeNumber]").attr("content")
                        let episodeHref = try element.select("td.season3EpisodeID a").attr("href")
                        let href = "https://aniworld.to" + episodeHref
                        
                        return Episode(number: episodeNumber, href: href, downloadUrl: "")
                    } catch {
                        print("Error parsing AniWorld episode: \(error.localizedDescription)")
                        return nil
                    }
                }
            default:
                episodes = episodeElements.compactMap { element in
                    guard let episodeText = try? element.text(),
                          let href = try? element.attr("href") else { return nil }
                    let downloadUrl = try? document.select(downloadUrlElement).attr("href")
                    return Episode(number: episodeText, href: href, downloadUrl: downloadUrl ?? "")
                }
            }
        } catch {
            print("Error parsing episodes: \(error.localizedDescription)")
        }
        return episodes
    }
}
