//
//  SettingsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectSourceButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Select Source", message: "Choose your preferred source for AnimeLounge.", preferredStyle: .actionSheet)
        
        let animeWorldAction = UIAlertAction(title: "AnimeWorld", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animeWorld
        }
        
        let monosChinosAction = UIAlertAction(title: "MonosChinos", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .monoschinos
        }
        
        let gogoAnimeAction = UIAlertAction(title: "GoGoAnime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .gogoanime
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(animeWorldAction)
        actionSheet.addAction(monosChinosAction)
        actionSheet.addAction(gogoAnimeAction)
        actionSheet.addAction(cancelAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
}
