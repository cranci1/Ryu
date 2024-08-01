//
//  FeaturedAnimeParsing.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit
import SwiftSoup

extension HomeViewController {
    func getSourceInfo(for source: String) -> (String?, ((Document) throws -> [AnimeItem])?) {
        switch source {
        case "AnimeWorld":
            return ("https://www.animeworld.so", parseAnimeWorldFeatured)
        case "GoGoAnime":
            return ("https://anitaku.pe/home.html", parseGoGoFeatured)
        case "AnimeHeaven":
            return ("https://animeheaven.me/new.php", parseAnimeHeavenFeatured)
        case "AnimeFire":
            return ("https://animefire.plus/", parseAnimeFireFeatured)
        case "Kuramanime":
            return ("https://kuramanime.boo/quick/ongoing?order_by=updated", parseKuramanimeFeatured)
        case "JKanime":
            return ("https://jkanime.net/", parseJKAnimeFeatured)
        default:
            return (nil, nil)
        }
    }
    
    func parseAnimeWorldFeatured(_ doc: Document) throws -> [AnimeItem] {
        let contentDiv = try doc.select("div.content[data-name=all]").first()
          guard let animeItems = try contentDiv?.select("div.item") else {
              throw NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find anime items"])
          }
        
        return try animeItems.array().compactMap { item in
            let titleElement = try item.select("a.name").first()
            let title = try titleElement?.text() ?? ""
              
            let imageElement = try item.select("img").first()
            let imageURL = try imageElement?.attr("src") ?? ""
            
            let episodeElement = try item.select("div.ep").first()
            let episodeText = try episodeElement?.text() ?? ""
            let episode = episodeText.replacingOccurrences(of: "Ep ", with: "")
            
            let hrefElement = try item.select("a.poster").first()
            let href = try hrefElement?.attr("href") ?? ""
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    func parseGoGoFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.last_episodes li")
        return try animeItems.array().compactMap { item in
            let title = try item.select("p.name a").text()
            
            let episodeText = try item.select("p.episode").text()
            let episode = episodeText.replacingOccurrences(of: "Episode ", with: "")
            
            let imageURL = try item.select("div.img img").attr("src")
            var href = try item.select("div.img a").attr("href")
            
            if let range = href.range(of: "-episode-\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            href = "/category" + href
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    func parseAnimeHeavenFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.boldtext div.chart.bc1")
        return try animeItems.array().compactMap { item in
            let title = try item.select("div.chartinfo a.c").text()
            let episode = try item.select("div.chartep").text()
            
            let imageURL = try item.select("div.chartimg img").attr("src")
            let image = "https://animeheaven.me/" + imageURL
            
            let href = try item.select("div.chartimg a").attr("href")
            
            return AnimeItem(title: title, episode: episode, imageURL: image, href: href)
        }
    }
    
    func parseAnimeFireFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.container.eps div.card-group div.col-12")
        return try animeItems.array().compactMap { item in
            
            var title = try item.select("h3.animeTitle").text()
            
            if let range = title.range(of: "- Episódio \\d+", options: .regularExpression) {
                title.removeSubrange(range)
            }
            
            let episodeText = try item.select("span.numEp").text()
            let episode = episodeText.replacingOccurrences(of: "Episódio ", with: "")
            
            let imageURL = try item.select("article.card img").attr("src")
            let href = try item.select("article.card a").attr("href")
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    func parseKuramanimeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.product__page__content div#animeList div.col-lg-4")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h5 a").text()
            
            let episodeText = try item.select("div.ep span").text()
            let episodeRegex = try NSRegularExpression(pattern: "^Ep (\\d+)", options: [])
            let matches = episodeRegex.matches(in: episodeText, options: [], range: NSRange(location: 0, length: episodeText.utf16.count))
            let episode = matches.first.flatMap {
                String(episodeText[Range($0.range(at: 1), in: episodeText)!])
            } ?? ""
            
            let imageURL = try item.select("div.product__item__pic").attr("data-setbg")
            
            var href = try item.select("a").attr("href")
            if let range = href.range(of: "/episode/\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    func parseJKAnimeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.listadoanime-home div.anime_programing a.bloqq")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("div.anime__sidebar__comment__item__text h5").text()
            let episodeText = try item.select("div.anime__sidebar__comment__item__text h6").text()
            let episode = episodeText.replacingOccurrences(of: "Episodio ", with: "")
            let imageURL = try item.select("img").attr("src")
            
            var href = try item.select("a").attr("href")
            if let range = href.range(of: "/\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
}
