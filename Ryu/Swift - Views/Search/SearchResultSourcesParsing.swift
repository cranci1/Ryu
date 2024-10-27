//
//  SearchResultSourcesParsing.swift
//  Ryu
//
//  Created by Francesco on 13/07/24.
//

import UIKit
import SwiftSoup

extension SearchResultsViewController {
    func parseAnimeWorld(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select(".film-list .item")
            return try items.map { item -> (title: String, imageUrl: String, href: String) in
                let title = try item.select("a.name").text()
                let imageUrl = try item.select("a.poster img").attr("src")
                let href = try item.select("a.poster").attr("href")
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing AnimeWorld: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseGoGoAnime(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("ul.items li")
            return try items.compactMap { item -> (title: String, imageUrl: String, href: String)? in
                guard let linkElement = try item.select("a").first(),
                      let href = try? linkElement.attr("href"),
                      let imageUrl = try? linkElement.select("img").attr("src") else {
                          return nil
                      }
                
                var title = (try? linkElement.attr("title")).flatMap { $0.isEmpty ? nil : $0 }
                ?? (try? linkElement.select("img").attr("alt")).flatMap { $0.isEmpty ? nil : $0 }
                ?? (try? item.select("p.name > a").text()).flatMap { $0.isEmpty ? nil : $0 }
                ?? ""
                
                title = title.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                
                guard !title.isEmpty else { return nil }
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing GoGoAnime: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseAnimeHeaven(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("div.info3.bc1 div.similarimg")
            return try items.map { item -> (title: String, imageUrl: String, href: String) in
                let linkElement = try item.select("a").first()
                let href = try linkElement?.attr("href") ?? ""
                var imageUrl = try linkElement?.select("img").attr("src") ?? ""
                if !imageUrl.isEmpty && !imageUrl.hasPrefix("http") {
                    imageUrl = "https://animeheaven.me/\(imageUrl)"
                }
                let title = try item.select("div.similarname a.c").text()
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing AnimeHeaven: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseAnimeFire(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("div.card-group div.row div.divCardUltimosEps")
            return try items.compactMap { item -> (title: String, imageUrl: String, href: String)? in
                guard let title = try item.select("div.text-block h3.animeTitle").first()?.text(),
                      let imageUrl = try item.select("article.card a img").first()?.attr("data-src"),
                      let href = try item.select("article.card a").first()?.attr("href")
                else { return nil }
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing AnimeFire: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseKuramanime(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("div#animeList div.col-lg-4")
            return try items.map { item -> (title: String, imageUrl: String, href: String) in
                let title = try item.select("div.product__item__text h5 a").text()
                let imageUrl = try item.select("div.product__item__pic").attr("data-setbg")
                let href = try item.select("div.product__item a").attr("href")
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing Kuramanime: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseJKanime(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("div.anime__page__content div.row div.col-lg-2")
            return try items.map { item -> (title: String, imageUrl: String, href: String) in
                let title = try item.select("h5").text()
                let imageUrl = try item.select("div.anime__item__pic").attr("data-setbg")
                let href = try item.select("a").attr("href")
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing JKanime: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseAnime3rb(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("section div.my-2")
            return try items.map { item -> (title: String, imageUrl: String, href: String) in
                let title = try item.select("h2.pt-1").text()
                let imageUrl = try item.select("img").attr("src")
                let href = try item.select("a").first()?.attr("href") ?? ""
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing Anime3rb: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseHiAnime(_ jsonString: String) -> [(title: String, imageUrl: String, href: String)] {
        do {
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                print("Error converting JSON string to Data")
                return []
            }
            
            let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            
            guard let animes = json?["animes"] as? [[String: Any]] else {
                print("Error extracting 'animes' array from JSON")
                return []
            }
            
            return animes.map { anime -> (title: String, imageUrl: String, href: String) in
                let title = anime["name"] as? String ?? "Unknown Title"
                let imageUrl = anime["poster"] as? String ?? ""
                let href = anime["id"] as? String ?? ""
                return (title: title, imageUrl: imageUrl, href: href)
            }
        } catch {
            print("Error parsing HiAnime JSON: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseHanashi(_ jsonString: String) -> [(title: String, imageUrl: String, href: String)] {
        guard let data = jsonString.data(using: .utf8) else { return [] }
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                return json.compactMap { item in
                    guard let id = item["id"] as? String,
                          let names = item["name"] as? [[String: String]],
                          let images = item["images"] as? [String: [[String: Any]]] else {
                              return nil
                          }
                    
                    let title = names.first { $0["locale"] == "de-DE" }?["name"] ?? names.first?["name"] ?? ""
                    
                    let coverImages = images["cover"] ?? []
                    let pngImage = coverImages.first { $0["format"] as? String == "png" }
                    let parImageURL = pngImage?["source"] as? String ?? ""
                    let imageUrl = "https://api.hanashi.to/public/" + parImageURL
                    
                    return (title: title, imageUrl: imageUrl, href: id)
                }
            }
        } catch {
            print("Error parsing Hanashi JSON: \(error.localizedDescription)")
        }
        return []
    }
    
    func parseAnilibria(_ jsonString: String) -> [(title: String, imageUrl: String, href: String)] {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let list = jsonObject["list"] as? [[String: Any]] else {
                return []
            }
            
            return list.compactMap { anime -> (title: String, imageUrl: String, href: String)? in
                guard let id = anime["id"] as? Int,
                      let names = anime["names"] as? [String: Any],
                      let posters = anime["posters"] as? [String: Any],
                      let mediumPoster = posters["medium"] as? [String: Any],
                      let imageUrl = mediumPoster["url"] as? String else {
                    return nil
                }
                
                let title = (names["ru"] as? String) ?? (names["en"] as? String) ?? "Unknown Title"
                let imageURL = "https://anilibria.tv/" + imageUrl
                let href = String(id)
                
                return (title: title, imageUrl: imageURL, href: href)
            }
        } catch {
            print("Error parsing Anilibria JSON: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseAnimeSRBIJA(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let items = try document.select("div.ani-wrap div.ani-item")
            return try items.map { item -> (title: String, imageUrl: String, href: String) in
                let title = try item.select("h3.ani-title").text()
                
                let srcset = try item.select("img").attr("srcset")
                let imageUrl = srcset.components(separatedBy: ", ")
                    .last?
                    .components(separatedBy: " ")
                    .first ?? ""
                
                let imageURL = "https://www.animesrbija.com" + imageUrl
                
                let hrefBase = try item.select("a").first()?.attr("href") ?? ""
                let href = "https://www.animesrbija.com" + hrefBase
                
                return (title: title, imageUrl: imageURL, href: href)
            }
        } catch {
            print("Error parsing AnimeSRBIJA: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseAniWorld(_ document: Document) -> [(title: String, imageUrl: String, href: String)] {
        var results: [(title: String, imageUrl: String, href: String)] = []
        let searchQuery = query.lowercased()
        
        do {
            let genreElements = try document.select("div.genre")
            for genreElement in genreElements {
                let anchorElements = try genreElement.select("a")
                
                for anchor in anchorElements {
                    let title = try anchor.text()
                    let href = try anchor.attr("href")
                    if title.lowercased().contains(searchQuery) {
                        results.append((
                            title: title,
                            imageUrl: "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg",
                            href: "https://aniworld.to\(href)"
                        ))
                        print(href)
                    }
                }
            }
        } catch {
            print("Error parsing AniWorld HTML: \(error.localizedDescription)")
        }
        let sortedResults = results.sorted { $0.title.lowercased() < $1.title.lowercased() }
        return sortedResults
    }
}
