//
//  HiAnime-WebPlayer.swift
//  Ryu
//
//  Created by Francesco on 16/08/24.
//

import UIKit
import WebKit

class HiAnimeWebPlayer: UIViewController {
    var streamURL: String
    var captionURL: String
    var cell: EpisodeCell
    var fullURL: String
    weak var animeDetailsViewController: AnimeDetailViewController?
    
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.secondarySystemBackground
        
        view.addSubview(webView)
        view.addSubview(activityIndicator)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        let htmlContent = generateHTMLContent(videoURL: streamURL, captionsURL: captionURL)
        webView.loadHTMLString(htmlContent, baseURL: nil)
        webView.isHidden = UserDefaults.standard.bool(forKey: "hideWebPlayer")
        
        activityIndicator.startAnimating()
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
                <video controls autoplay>
                    <source src="\(videoURL)" type="application/x-mpegURL">
                    <track kind="captions" src="\(captionsURL)" srclang="en" label="English" default>
                    Your browser does not support the video tag. (fr tho)
                </video>
                <script>
                    var video = document.querySelector('video');
                    video.addEventListener('play', function() {
                        window.webkit.messageHandlers.videoPlay.postMessage(null);
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
    
    deinit {
        stopAndCleanUpWebView()
    }
}

extension HiAnimeWebPlayer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        closeButton.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        stopAndCleanUpWebView()
        self.dismiss(animated: true)
    }
}
