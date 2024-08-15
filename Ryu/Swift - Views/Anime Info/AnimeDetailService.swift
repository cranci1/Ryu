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
        
        let baseUrl: String
        switch selectedSource {
        case .animeWorld:
            baseUrl = "https://animeworld.so"
        case .gogoanime:
            baseUrl = "https://anitaku.pe"
        case .animeheaven:
            baseUrl = "https://animeheaven.me/"
        case .animefire, .kuramanime, .jkanime, .anime3rb:
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
                episodeElements = try document.select("ul#episode_page a")
                downloadUrlElement = ""
            case .animeheaven:
                episodeElements = try document.select("a[href^='episode.php']")
                downloadUrlElement = ""
            case .animefire:
                episodeElements = try document.select("div.div_video_list a")
                downloadUrlElement = ""
            case .kuramanime:
                let episodeContent = try document.select("div.d-inline a.follow-btn").attr("data-content")
                let episodeDocument = try SwiftSoup.parse(episodeContent)
                episodeElements = try episodeDocument.select("a.btn")
                downloadUrlElement = ""
            case .jkanime:
                episodeElements = try document.select("div.anime__pagination a.numbers")
                downloadUrlElement = ""
            case .anime3rb:
                episodeElements = try document.select("div.absolute.overflow-hidden div a.gap-3")
                downloadUrlElement = ""
            }
            
            switch source {
            case .gogoanime:
                episodes = episodeElements.flatMap { element -> [Episode] in
                    guard let startStr = try? element.attr("ep_start"), let endStr = try? element.attr("ep_end"),
                          let start = Int(startStr), let end = Int(endStr) else { return [] }
                    
                    return (max(1, start)...end).map { episodeNumber in
                        let formattedEpisode = "\(episodeNumber)"
                        let episodeHref = "\(href)-episode-\(episodeNumber)"
                        let downloadUrl = try? document.select(downloadUrlElement).attr("href")
                        
                        return Episode(number: formattedEpisode, href: episodeHref, downloadUrl: downloadUrl ?? "")
                    }
                }
            case .animeheaven:
                episodes = episodeElements.compactMap { element in
                    guard let episodeNumberElement = try? element.select("div.watch2.bc.c").first() else {
                        return nil
                    }
                    
                    let episodeNumber = try? episodeNumberElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let href = try? element.attr("href")
                    
                    if let episodeNumber = episodeNumber, let href = href {
                        return Episode(number: episodeNumber, href: href, downloadUrl: "")
                    } else {
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
                        print("Error parsing episode: \(error.localizedDescription)")
                    }
                    return nil
                }
            case .kuramanime:
                episodes = episodeElements.compactMap { element in
                    guard let episodeText = try? element.text(),
                          let href = try? element.attr("href") else { return nil }
                    
                    let episodeNumber = episodeText.replacingOccurrences(of: "Ep ", with: "")
                    return Episode(number: episodeNumber, href: href, downloadUrl: "")
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
                        print("Error parsing episode: \(error.localizedDescription)")
                        return nil
                    }
                }
            default:
                episodes = episodeElements.compactMap { element in
                    guard let episodeText = try? element.text(),
                          let href = try? element.attr("href") else { return nil }
                    let downloadUrl = try? document.select(downloadUrlElement).attr("href")
                    print("\(href)")
                    return Episode(number: episodeText, href: href, downloadUrl: downloadUrl ?? "")
                }
            }
        } catch {
            print("Error parsing episodes: \(error.localizedDescription)")
        }
        return episodes
    }
}
