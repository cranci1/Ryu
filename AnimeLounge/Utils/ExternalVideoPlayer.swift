//
//  ExternalVideoPlayer.swift
//  AnimeLounge
//
//  Created by Francesco on 03/07/24.
//

import WebKit
import Combine
import AVKit

class ExternalVideoPlayer: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView?
    private var clickCancellable: AnyCancellable?
    private var loadingObserver: NSKeyValueObservation?
    private var avPlayerViewController: AVPlayerViewController?
    private var isVideoPlaying = false
    private var streamURL: String
    
    init(streamURL: String) {
        self.streamURL = streamURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoadingView()
        openWebView(fullURL: streamURL)
    }
    
    private func setupLoadingView() {
        view.backgroundColor = .black
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }
    
    private func startMonitoringPlayState(interval: TimeInterval) {
        stopMonitoringPlayState()
        
        clickCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAndClickPlayButton()
            }
        
        checkAndClickPlayButton()
    }
    
    private func stopMonitoringPlayState() {
        clickCancellable?.cancel()
        clickCancellable = nil
    }
    
    private func checkAndClickPlayButton() {
        guard let webView = self.webView, !isVideoPlaying else {
            return
        }
        
        let script = """
        (function() {
            var player = jwplayer();
            if (player && player.getState() === 'idle') {
                var playButton = document.querySelector('.jw-icon.jw-icon-display.jw-button-color.jw-reset');
                if (playButton) {
                    playButton.click();
                    return 'Clicked play button';
                }
            }
            return player ? player.getState() : 'Player not found';
        })();
        """
        
        webView.evaluateJavaScript(script) { (result, error) in
            if let error = error {
                print("Error executing JavaScript: \(error)")
            } else if let result = result as? String {
                print("Player state: \(result)")
            }
        }
    }
    
    private func openWebView(fullURL: String) {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "videoHandler")
        configuration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.isHidden = true
        if let webView = webView {
            view.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        setupLoadingObserver()
        
        if let url = URL(string: fullURL) {
            let request = URLRequest(url: url)
            webView?.load(request)
        }
    }
    
    private func setupLoadingObserver() {
        loadingObserver = webView?.observe(\.isLoading, options: [.new]) { [weak self] _, change in
            if let isLoading = change.newValue, !isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.injectCustomJavaScript()
                    self?.startMonitoringPlayState(interval: 2.0)
                }
            }
        }
    }
    
    private func injectCustomJavaScript() {
        let script = """
        function notifyVideoState(state, videoUrl) {
            window.webkit.messageHandlers.videoHandler.postMessage({state: state, url: videoUrl});
        }
        
        if (typeof jwplayer !== 'undefined') {
            var player = jwplayer();
            player.on('play', function() {
                var videoUrl = player.getPlaylistItem().file;
                notifyVideoState('play', videoUrl);
            });
            player.on('pause', function() { notifyVideoState('pause', null); });
            player.on('complete', function() { notifyVideoState('complete', null); });
            player.on('error', function() { notifyVideoState('error', null); });
        }
        """
        
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoHandler" {
            if let dict = message.body as? [String: Any],
               let state = dict["state"] as? String {
                print("Video state changed: \(state)")
                if state == "play" {
                    stopMonitoringPlayState()
                    if let videoUrlString = dict["url"] as? String,
                       let videoUrl = URL(string: videoUrlString) {
                        DispatchQueue.main.async {
                            self.playVideoInAVPlayer(url: videoUrl)
                        }
                    }
                } else if state == "pause" || state == "complete" || state == "error" {
                    isVideoPlaying = false
                    startMonitoringPlayState(interval: 2.0)
                }
            }
        }
    }
    
    private func playVideoInAVPlayer(url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        playerViewController.didMove(toParent: self)
        
        player.play()
        isVideoPlaying = true
    }
    
    deinit {
        stopMonitoringPlayState()
        loadingObserver?.invalidate()
    }
}
