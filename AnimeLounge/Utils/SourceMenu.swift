//
//  SourceMenu.swift
//  AnimeLounge
//
//  Created by Francesco on 05/07/24.
//

import UIKit

class SourceMenu {
    static func showSourceSelector(from viewController: UIViewController, sourceView: UIView) {
        let sources: [(title: String, source: MediaSource)] = [
            ("AnimeWorld", .animeWorld),
            ("GoGoAnime", .gogoanime),
            ("AnimeHeaven", .animeheaven),
            ("AnimeFire", .animefire),
            ("Kuramanime", .kuramanime),
            ("Latanime", .latanime),
            ("Anime3rb", .anime3rb),
            ("AnimeToast", .animetoast),
            ("AniWave", .aniwave)
        ]
        
        let alertController = UIAlertController(title: "Select Source", message: "Choose your preferred source for AnimeLounge.", preferredStyle: .actionSheet)
        
        for (title, source) in sources {
            let action = UIAlertAction(title: title, style: .default) { _ in
                UserDefaults.standard.selectedMediaSource = source
            }
            setSourceImage(for: action, named: title)
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }
        
        viewController.present(alertController, animated: true)
    }
    
    private static func setSourceImage(for action: UIAlertAction, named imageName: String) {
        guard let originalImage = UIImage(named: imageName) else { return }
        let resizedImage = originalImage.resized(to: CGSize(width: 35, height: 35))
        action.setValue(resizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
    }
}
