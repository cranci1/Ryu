//
//  AnimeDetailService.swift
//  AnimeLounge
//
//  Created by Francesco on 25/06/24.
//

import Alamofire
import SwiftSoup
import UIKit

struct AnimeDetail {
    let aliases: String
    let synopsis: String
    let episodes: [Episode]
}

class AnimeDetailService {
    
    static func fetchAnimeDetails(from href: String, completion: @escaping (Result<AnimeDetail, Error>) -> Void) {
        guard let selectedSource = UserDefaults.standard.selectedMediaSource else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No media source selected."])))
            return
        }
        
        let baseUrl: String
        switch selectedSource {
        case .animeWorld:
            baseUrl = "https://animeworld.so"
        case .gogoanime:
            baseUrl = "https://anitaku.pe"
        case .tioanime:
            baseUrl = "https://tioanime.com"
        case .animeheaven:
            baseUrl = "https://animeheaven.me/"
        }
        
        let fullUrl = baseUrl + href
        AF.request(fullUrl).responseString { response in
            switch response.result {
            case .success(let html):
                do {
                    let document = try SwiftSoup.parse(html)
                    let aliases: String
                    let synopsis: String
                    let episodes: [Episode]
                    
                    switch selectedSource {
                    case .animeWorld:
                        aliases = ""
                        synopsis = try document.select("div.info div.desc").text()
                    case .gogoanime:
                        aliases = try document.select("div.anime_info_body_bg p.other-name a").text()
                        synopsis = try document.select("div.anime_info_body_bg div.description").text()
                    case .tioanime:
                        aliases = try document.select("p.original-title").text()
                        synopsis = try document.select("p.sinopsis").text()
                    case .animeheaven:
                        aliases = try document.select("div.infodiv div.infotitlejp").text()
                        synopsis = try document.select("div.infodiv div.infodes").text()
                    }
                    
                    episodes = self.fetchEpisodes(document: document, for: selectedSource, href: href)
                    
                    let details = AnimeDetail(aliases: aliases, synopsis: synopsis, episodes: episodes)
                    completion(.success(details))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private static func fetchEpisodes(document: Document, for source: MediaSource, href: String) -> [Episode] {
        var episodes: [Episode] = []
        do {
            var episodeElements: Elements
            
            switch source {
            case .animeWorld:
                episodeElements = try document.select("div.server.active ul.episodes li.episode a")
            case .gogoanime:
                episodeElements = try document.select("a.active")
            case .tioanime:
                episodeElements = try document.select("ul.episodes-list li")
            case .animeheaven:
                episodeElements = try document.select("div.linetitle2 a")
            }
            
            switch source {
            case .gogoanime:
                episodes = episodeElements.flatMap { element -> [Episode] in
                    guard let episodeText = try? element.text() else { return [] }
                    
                    let parts = episodeText.split(separator: "-")
                    guard parts.count == 2,
                          let start = Int(parts[0]),
                          let end = Int(parts[1]) else {
                        return []
                    }
                    
                    return (max(1, start)...end).map { episodeNumber in
                        let formattedEpisode = "\(episodeNumber)"
                        let episodeHref = "\(href)-episode-\(episodeNumber)"
                        
                        return Episode(number: formattedEpisode, href: episodeHref)
                    }
                }
            default:
                episodes = episodeElements.compactMap { element in
                    guard let episodeText = try? element.text(),
                          let href = try? element.attr("href") else { return nil }
                    return Episode(number: episodeText, href: href)
                }
            }
        } catch {
            print("Error parsing episodes: \(error.localizedDescription)")
        }
        return episodes
    }
}

