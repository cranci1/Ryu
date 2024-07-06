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
        
        let baseUrl: String
        switch selectedSource {
        case .animeWorld:
            baseUrl = "https://animeworld.so"
        case .gogoanime:
            baseUrl = "https://anitaku.pe"
        case .animeheaven:
            baseUrl = "https://animeheaven.me/"
        case .animefire, .kuramanime, .latanime, .animetoast:
            baseUrl = ""
        }
        
        let fullUrl = baseUrl + href
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
                        stars =  ""
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
                    case .latanime:
                        aliases = ""
                        synopsis = try document.select("div.col-md-8 p").last()?.text() ?? ""
                        airdate = try document.select("div.col-md-8 div.my-2 span").last()?.text().replacingOccurrences(of: "Estreno: ", with: "") ?? ""
                        stars = ""
                    case .animetoast:
                         aliases = try document.select("div.col-md-8 p").last()?.text() ?? ""
                         synopsis = try document.select("div.col-md-8 p").eq(0).text()
                         airdate = try document.select("div.col-md-8 p").eq(2).text().replacingOccurrences(of: "Season Start: ", with: "")
                         stars = ""
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
                episodeElements = try document.select("a.active")
                downloadUrlElement = ""
            case .animeheaven:
                episodeElements = try document.select("div.linetitle2 a")
                downloadUrlElement = ""
            case .animefire:
                episodeElements = try document.select("div.div_video_list a")
                downloadUrlElement = ""
            case .kuramanime:
                if let episodeCountText = try? document.select("div.col-lg-6.col-md-6 ul li:contains(Episode:) div.col-9 a").text(),
                   let episodeCount = Int(episodeCountText) {
                    episodes = (1...episodeCount).map { episodeNumber in
                        let formattedEpisode = "\(episodeNumber)"
                        let episodeHref = "\(href)/episode/\(episodeNumber)"
                        return Episode(number: formattedEpisode, href: episodeHref, downloadUrl: "")
                    }
                }
                return episodes
            case .latanime:
                episodeElements = try document.select("div.row div.row div a")
                downloadUrlElement = ""
            case .animetoast:
                episodeElements = try document.select("div.tab-content div#multi_link_tab1 a.multilink-btn")
                downloadUrlElement = ""
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
                        let downloadUrl = try? document.select(downloadUrlElement).attr("href")
                        
                        return Episode(number: formattedEpisode, href: episodeHref, downloadUrl: downloadUrl ?? "")
                    }
                }
            case .animetoast:
                episodes = episodeElements.compactMap { element in
                    guard let episodeText = try? element.text(),
                          let href = try? element.attr("href") else { return nil }
                    
                    let episodeNumber = episodeText.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .joined()
                    
                    return Episode(number: episodeNumber, href: href, downloadUrl: "")
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
