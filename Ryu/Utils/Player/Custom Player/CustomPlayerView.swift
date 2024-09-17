//
//  CustomPlayerView.swift
//  Ryu
//
//  Created by Francesco on 24/08/24.
//

import UIKit
import AVKit

class CustomPlayerView: UIViewController {
    
    private var playerView: CustomVideoPlayerView!
    
    private var videoTitle: String
    private var videoURL: URL
    private var subURL: URL?
    private var cell: EpisodeCell
    private var fullURL: String
    private var animeImage: String
    
    weak var delegate: CustomPlayerViewDelegate?
    
    init(videoTitle: String, videoURL: URL, subURL: URL? = nil, cell: EpisodeCell, fullURL: String, image: String) {
        self.videoTitle = videoTitle
        self.videoURL = videoURL
        self.subURL = subURL
        self.cell = cell
        self.fullURL = fullURL
        self.animeImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupAudioSession()
        
        playerView = CustomVideoPlayerView(frame: view.bounds, cell: cell, fullURL: fullURL, image: animeImage)
        view.addSubview(playerView)
        
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        playerView.setVideo(url: videoURL, title: videoTitle, subURL: subURL, cell: cell, fullURL: fullURL)
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: .mixWithOthers)
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UserDefaults.standard.bool(forKey: "AlwaysLandscape") {
            return .landscape
        } else {
            return .all
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView.pause()
        delegate?.customPlayerViewDidDismiss()
    }
}

protocol CustomPlayerViewDelegate: AnyObject {
    func customPlayerViewDidDismiss()
}
