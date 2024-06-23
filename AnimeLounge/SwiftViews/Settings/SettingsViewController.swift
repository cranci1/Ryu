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
        let actionSheet = UIAlertController(title: "Select Source", message: "Choose your preferred source", preferredStyle: .actionSheet)
        
        let animeWorldAction = UIAlertAction(title: "AnimeWorld", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animeWorld
        }
        
        let anotherSourceAction = UIAlertAction(title: "MonosChinos", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .monoschinos
        }
        
        let thirdSourceAction = UIAlertAction(title: "GoGoAnime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .gogoanime
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(animeWorldAction)
        actionSheet.addAction(anotherSourceAction)
        actionSheet.addAction(thirdSourceAction)
        actionSheet.addAction(cancelAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
}
