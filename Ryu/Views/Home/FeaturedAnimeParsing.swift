//
//  FeaturedAnimeParsing.swift
//  Ryu
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
            return ("https://gogoanime3.cc/home.html", parseGoGoFeatured)
        case "AnimeHeaven":
            return ("https://animeheaven.me/new.php", parseAnimeHeavenFeatured)
        case "AnimeFire":
            return ("https://animefire.plus/", parseAnimeFireFeatured)
        case "Kuramanime":
            return ("https://kuramanime.red/quick/ongoing?order_by=updated", parseKuramanimeFeatured)
        case "Anime3rb":
            return ("https://anime3rb.com/titles/list?status[0]=upcomming&status[1]=finished&sort_by=addition_date", parseAnime3rbFeatured)
        case "HiAnime":
            return ("https://hianime.to/home", parseHiAnimeFeatured)
        case "Anilibria":
            return ("https://api.anilibria.tv/v3/title/updates?filter=posters,id,names&limit=20", parseAniLibriaFeatured)
        case "AnimeSRBIJA":
            return ("https://www.animesrbija.com/filter?sort=new", paseAnimeSRBIJAFeatured)
        case "AniWorld":
            return ("https://aniworld.to/neu", paseAniWorldFeatured)
        case "TokyoInsider":
            return ("https://www.tokyoinsider.com/new", paseTokyoFeatured)
        case "AniVibe":
            return ("https://anivibe.net/newest", paseAniVibeFeatured)
        case "AnimeUnity":
            return ("https://www.animeunity.to/", parseAnimeUnityFeatured)
        case "AnimeFLV":
            return ("https://www3.animeflv.net/", paseAnimeFLVFeatured)
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
            
            let hrefElement = try item.select("a.poster").first()
            let href = try hrefElement?.attr("href") ?? ""
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func parseGoGoFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.last_episodes li")
        return try animeItems.array().compactMap { item in
            let title = try item.select("p.name a").text()
            
            let imageURL = try item.select("div.img img").attr("src")
            var href = try item.select("div.img a").attr("href")
            
            if let range = href.range(of: "-episode-\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            href = "/category" + href
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func parseAnimeHeavenFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.boldtext div.chart.bc1")
        return try animeItems.array().compactMap { item in
            let title = try item.select("div.chartinfo a.c").text()
            
            let imageURL = try item.select("div.chartimg img").attr("src")
            let image = "https://animeheaven.me/" + imageURL
            
            let href = try item.select("div.chartimg a").attr("href")
            
            return AnimeItem(title: title, imageURL: image, href: href)
        }
    }
    
    func parseAnimeFireFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.container.eps div.card-group div.col-12")
        return try animeItems.array().compactMap { item in
            
            var title = try item.select("h3.animeTitle").text()
            if let range = title.range(of: "- Episódio \\d+", options: .regularExpression) {
                title.removeSubrange(range)
            }
            
            var imageURL = try item.select("article.card img").attr("src")
            
            if imageURL.isEmpty {
                imageURL = "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg"
            }
            
            var href = try item.select("article.card a").attr("href")
            
            if let range = href.range(of: "/\\d+$", options: .regularExpression) {
                href.replaceSubrange(range, with: "-todos-os-episodios")
            }
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func parseKuramanimeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.product__page__content div#animeList div.col-lg-4")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h5 a").text()
            
            let imageURL = try item.select("div.product__item__pic").attr("data-setbg")
            
            var href = try item.select("a").attr("href")
            if let range = href.range(of: "/episode/\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func parseAnime3rbFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.flex.flex-wrap.justify-center div.my-2")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h2.text-ellipsis").text()
            
            let imageURL = try item.select("img").attr("src")
            let href = try item.select("a").attr("href")
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func parseHiAnimeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("section.block_area.block_area_home div.film_list-wrap div.flw-item")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h3.film-name a").text()
            
            let imageURL = try item.select("img").attr("data-src")
            
            var href = try item.select("a.film-poster-ahref").attr("href")
            if href.hasPrefix("/watch/") {
                href.removeFirst("/watch/".count)
            }
            if let queryIndex = href.firstIndex(of: "?") {
                href = String(href[..<queryIndex])
            }
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func parseAniLibriaFeatured(_ doc: Document) throws -> [AnimeItem] {
        guard let preElement = try doc.select("body").first() else {
            throw NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find body element in document"])
        }
        
        let jsonString = try preElement.html()
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert JSON string to Data"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            throw NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
        }
        
        guard let list = json["list"] as? [[String: Any]] else {
            throw NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure: missing or invalid 'list' key"])
        }
        
        return list.compactMap { item in
            guard let id = item["id"] as? Int,
                  let names = item["names"] as? [String: Any],
                  let title = names["ru"] as? String,
                  let posters = item["posters"] as? [String: Any],
                  let medium = posters["medium"] as? [String: Any],
                  let posterURL = medium["url"] as? String else {
                return nil
            }
            
            let imageURL = "https://anilibria.tv" + posterURL
            let href = String(id)
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func paseAnimeSRBIJAFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.ani-wrap div.ani-item")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h3.ani-title").text()
            
            let srcset = try item.select("img").attr("srcset")
            let imageUrl = srcset.components(separatedBy: ", ")
                .last?
                .components(separatedBy: " ")
                .first ?? ""
            
            let imageURL = "https://www.animesrbija.com" + imageUrl
            
            let hrefBase = try item.select("a").first()?.attr("href") ?? ""
            let href = "https://www.animesrbija.com" + hrefBase
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func paseAniWorldFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.seriesListSection div.seriesListContainer div")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h3").text()
            
            let imageUrl = try item.select("img").attr("data-src")
            let imageURL = "https://aniworld.to" + imageUrl
            
            let hrefBase = try item.select("a").first()?.attr("href") ?? ""
            let href = "https://aniworld.to" + hrefBase
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func paseTokyoFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div#inner_page div.c_h2b, div#inner_page div.c_h2")
        return try animeItems.array().compactMap { item in
            
            var title = try item.select("a").text()
            if let range = title.range(of: "\\s*(episode|special)", options: .regularExpression, range: nil, locale: nil) {
                title = title.prefix(upTo: range.lowerBound).trimmingCharacters(in: .whitespaces)
            }
            
            let imageURL = "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg"
            
            let hrefBase = try item.select("a").first()?.attr("href").components(separatedBy: ")").first! ?? ""
            let href = "https://www.tokyoinsider.com" + hrefBase + ")"
            
            return AnimeItem(title: title, imageURL: imageURL, href: href)
        }
    }
    
    func paseAniVibeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.listupd article")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("div.tt span").text()
            
            var imageUrl = try item.select("img").attr("src")
            imageUrl = imageUrl.replacingOccurrences(of: "small", with: "default")
            
            let href = try item.select("a").first()?.attr("href") ?? ""
            let hrefFull = "https://anivibe.net" + href
            
            return AnimeItem(title: title, imageURL: imageUrl, href: hrefFull)
        }
    }
    
    func parseAnimeUnityFeatured(_ doc: Document) throws -> [AnimeItem] {
        let baseURL = "https://www.animeunity.to/anime/"
        
        do {
            let rawHtml = try doc.html()
            
            if let startIndex = rawHtml.range(of: "items-json=\"")?.upperBound,
               let endIndex = rawHtml.range(of: "\"", range: startIndex..<rawHtml.endIndex)?.lowerBound {
                
                let jsonString = String(rawHtml[startIndex..<endIndex])
                    .replacingOccurrences(of: "&quot;", with: "\"")
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let data = json["data"] as? [[String: Any]] {
                    
                    return data.compactMap { record in
                        guard let anime = record["anime"] as? [String: Any],
                              let title = anime["title"] as? String ?? anime["title_eng"] as? String,
                              let imageUrl = anime["imageurl"] as? String,
                              let animeID = anime["id"] as? Int,
                              let slug = anime["slug"] as? String else {
                            return nil
                        }
                        
                        let hrefFull = "\(baseURL)\(animeID)-\(slug)"
                        return AnimeItem(title: title, imageURL: imageUrl, href: hrefFull)
                    }
                }
            }
            
            print("Could not find or parse layout-items JSON")
            return []
        } catch {
            print("Error parsing AnimeUnity: \(error.localizedDescription)")
            return []
        }
    }
    
    func paseAnimeFLVFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("ul.ListEpisodios li")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("strong.Title").text()
            
            let imageUrl = try item.select("img").attr("src")
            let imageURL = "https://www3.animeflv.net" + imageUrl
            
            let href = try item.select("a").first()?.attr("href") ?? ""
            let hrefFull = "https://www3.animeflv.net" + href
            let modifiedHref = hrefFull.components(separatedBy: "-").dropLast().joined(separator: "-")
            let modifiedHref2 = modifiedHref.replacingOccurrences(of: "/ver/", with: "/anime/")
            
            print(modifiedHref2)
            return AnimeItem(title: title, imageURL: imageURL, href: modifiedHref2)
        }
    }
}
