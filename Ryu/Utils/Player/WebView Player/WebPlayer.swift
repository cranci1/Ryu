//
//  HiAnime-WebPlayer.swift
//  Ryu
//
//  Created by Francesco on 16/08/24.
//

import UIKit
import WebKit
import AVFoundation

class WebPlayer: UIViewController {
    var streamURL: String
    var captionURL: String
    var cell: EpisodeCell
    var fullURL: String
    weak var animeDetailsViewController: AnimeDetailViewController?
    
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    init(streamURL: String, captionURL: String, cell: EpisodeCell, fullURL: String, animeDetailsViewController: AnimeDetailViewController) {
        self.streamURL = streamURL
        self.captionURL = captionURL
        self.cell = cell
        self.fullURL = fullURL
        self.animeDetailsViewController = animeDetailsViewController
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .fullScreen
        self.isModalInPresentation = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoPlay")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoEnd")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "timeUpdate")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "closePlayer")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "exitFullscreen")
        stopAndCleanUpWebView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        view.addSubview(webView)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        let userContentController = webView.configuration.userContentController
        userContentController.add(self, name: "videoPlay")
        userContentController.add(self, name: "videoEnd")
        userContentController.add(self, name: "timeUpdate")
        userContentController.add(self, name: "closePlayer")
        userContentController.add(self, name: "exitFullscreen")
        
        let htmlContent = generateHTMLContent(videoURL: streamURL, captionsURL: captionURL)
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    private func generateHTMLContent(videoURL: String, captionsURL: String) -> String {
         """
         <!DOCTYPE html>
         <html lang="en">
         <head>
             <meta charset="UTF-8">
             <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
             <title>Video Player</title>
             <style>
                 body, html {
                     margin: 0;
                     padding: 0;
                     width: 100%;
                     height: 100%;
                     overflow: hidden;
                     background-color: black;
                 }
                 #videoContainer {
                     position: relative;
                     width: 100%;
                     height: 100%;
                 }
                 video {
                     position: absolute;
                     width: 100%;
                     height: 100%;
                     object-fit: contain;
                 }
                 ::cue {
                     background-color: transparent;
                     color: white;
                     font-size: 1.0em;
                     font-family: Arial, sans-serif;
                 }
             </style>
         </head>
         <body>
             <div id="videoContainer">
                 <video id="videoPlayer" controls autoplay playsinline>
                     <source src="\(videoURL)" type="video/mp4">
                     <track kind="captions" src="\(captionsURL)" srclang="en" label="English" default>
                     Your browser does not support the video tag.
                 </video>
                 <script>
                     var video = document.getElementById('videoPlayer');
         
                     video.addEventListener('play', function() {
                         if (video.requestFullscreen) {
                             video.requestFullscreen();
                         } else if (video.webkitRequestFullscreen) {
                             video.webkitRequestFullscreen();
                         } else if (video.msRequestFullscreen) {
                             video.msRequestFullscreen();
                         }
                         window.webkit.messageHandlers.videoPlay.postMessage(null);
                     });
         
                     document.addEventListener('fullscreenchange', handleFullscreenChange);
                     document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
                     document.addEventListener('mozfullscreenchange', handleFullscreenChange);
                     document.addEventListener('MSFullscreenChange', handleFullscreenChange);
                     
                     function handleFullscreenChange() {
                         if (!document.fullscreenElement &&
                             !document.webkitFullscreenElement &&
                             !document.mozFullScreenElement &&
                             !document.msFullscreenElement) {
                             window.webkit.messageHandlers.exitFullscreen.postMessage(null);
                         }
                     }
                     
                     video.addEventListener('ended', function() {
                         window.webkit.messageHandlers.videoEnd.postMessage(null);
                     });
                     
                     video.addEventListener('timeupdate', function() {
                         const currentTime = video.currentTime;
                         const duration = video.duration;
                         const progress = currentTime / duration;
                         const remainingTime = duration - currentTime;
                         
                         window.webkit.messageHandlers.timeUpdate.postMessage({
                             currentTime: currentTime,
                             duration: duration,
                             progress: progress,
                             remainingTime: remainingTime
                         });
                     });
                     
                     document.addEventListener('visibilitychange', function() {
                         if (document.visibilityState === 'hidden') {
                             window.webkit.messageHandlers.closePlayer.postMessage(null);
                         }
                     });
                     
                     window.addEventListener('popstate', function() {
                         window.webkit.messageHandlers.closePlayer.postMessage(null);
                     });
                 </script>
             </div>
         </body>
         </html>
         """
    }
    
    @objc private func closeButtonTapped() {
        stopAndCleanUpWebView()
        self.dismiss(animated: true)
    }
    
    private func stopAndCleanUpWebView() {
        webView.evaluateJavaScript("document.querySelector('video').pause();", completionHandler: nil)
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.removeFromSuperview()
    }
}

extension WebPlayer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        closeButton.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        stopAndCleanUpWebView()
        self.dismiss(animated: true)
    }
}

extension WebPlayer: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch message.name {
            case "timeUpdate":
                if let messageBody = message.body as? [String: Any],
                   let currentTime = messageBody["currentTime"] as? Double,
                   let duration = messageBody["duration"] as? Double,
                   let progress = messageBody["progress"] as? Double,
                   let remainingTime = messageBody["remainingTime"] as? Double {
                    
                    self.cell.updatePlaybackProgress(progress: Float(progress), remainingTime: remainingTime)
                    
                    UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(self.fullURL)")
                    UserDefaults.standard.set(duration, forKey: "totalTime_\(self.fullURL)")
                    
                    if let viewController = self.animeDetailsViewController,
                       let episodeNumber = viewController.episodes[safe: viewController.currentEpisodeIndex]?.number {
                        
                        if let episodeNumberInt = Int(episodeNumber) {
                            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "Anime3rb"
                            
                            let continueWatchingItem = ContinueWatchingItem(
                                animeTitle: viewController.animeTitle ?? "Unknown Anime",
                                episodeTitle: "Ep. \(episodeNumberInt)",
                                episodeNumber: episodeNumberInt,
                                imageURL: viewController.imageUrl ?? "",
                                fullURL: self.fullURL,
                                lastPlayedTime: currentTime,
                                totalTime: duration,
                                source: selectedMediaSource
                            )
                            ContinueWatchingManager.shared.saveItem(continueWatchingItem)
                            
                            let shouldSendPushUpdates = UserDefaults.standard.bool(forKey: "sendPushUpdates")
                            
                            if shouldSendPushUpdates && remainingTime < 90 && !viewController.hasSentUpdate {
                                let cleanedTitle = viewController.cleanTitle(viewController.animeTitle ?? "Unknown Anime")
                                
                                viewController.fetchAnimeID(title: cleanedTitle) { animeID in
                                    let aniListMutation = AniListMutation()
                                    aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: episodeNumberInt) { result in
                                        switch result {
                                        case .success():
                                            print("Successfully updated anime progress.")
                                        case .failure(let error):
                                            print("Failed to update anime progress: \(error.localizedDescription)")
                                        }
                                    }
                                    
                                    viewController.hasSentUpdate = true
                                }
                            }
                        }
                    }
                }
            case "videoEnd", "closePlayer", "exitFullscreen":
                self.stopAndCleanUpWebView()
                self.dismiss(animated: true)
            case "videoPlay":
                break
            default:
                break
            }
        }
    }
}
