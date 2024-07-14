//
//  ExternalVideoPlayer.swift
//  AnimeLounge
//
//  Created by Francesco on 03/07/24.
//

import AVKit
import WebKit
import Combine
import GoogleCast

class ExternalVideoPlayer: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, GCKRemoteMediaClientListener {
    private var webView: WKWebView?
    private var clickCancellable: AnyCancellable?
    private var loadingObserver: NSKeyValueObservation?
    private var playerViewController: AVPlayerViewController?
    private var isVideoPlaying = false
    private var streamURL: String
    private var activityIndicator: UIActivityIndicatorView?
    private var cell: EpisodeCell
    private var fullURL: String
    private weak var animeDetailsViewController: AnimeDetailViewController?

    init(streamURL: String, cell: EpisodeCell, fullURL: String, animeDetailsViewController: AnimeDetailViewController) {
        self.streamURL = streamURL
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
        setupLoadingView()
        openWebView(fullURL: streamURL)
    }

    private func setupLoadingView() {
        view.backgroundColor = .secondarySystemBackground
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.color = .white
        activityIndicator?.startAnimating()
        activityIndicator?.center = view.center
        if let activityIndicator = activityIndicator {
            view.addSubview(activityIndicator)
        }
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

        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "GoGoAnime"

        let script: String

        switch selectedMediaSource {
        case "GoGoAnime":
            script = """
            (function() {
                var player = jwplayer();
                if (player && player.getState() === 'idle') {
                    var playButton = document.querySelector('.jw-icon.jw-icon-display.jw-button-color.jw-reset');
                    if (playButton) {
                        playButton.click();
                        return 'Clicked play button for GoGoAnime';
                    }
                }
                return player ? player.getState() : 'Player not found';
            })();
            """
        default:
            script = """
            (function() {
                return 'Unknown media source';
            })();
            """
        }

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.injectCustomJavaScript()
                    self?.startMonitoringPlayState(interval: 1.0)
                }
            }
        }
    }

    private func injectCustomJavaScript() {
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "GoGoAnime"

        let script: String

        switch selectedMediaSource {
        case "GoGoAnime":
            script = """
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
        default:
            script = ""
        }

        webView?.evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                print("Error injecting custom JavaScript: \(error)")
            } else {
                self?.startCheckingForMediaPlayback()
            }
        }
    }
    
    private func startCheckingForMediaPlayback() {
          let script = """
          function checkMediaPlayback() {
              var video = document.querySelector('video');
              if (video && !video.paused) {
                  window.webkit.messageHandlers.videoHandler.postMessage({state: 'play', url: video.src});
                  return true;
              }
              return false;
          }
          checkMediaPlayback();
          """
          
          Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
              self?.webView?.evaluateJavaScript(script) { result, error in
                  if let isPlaying = result as? Bool, isPlaying {
                      timer.invalidate()
                  }
              }
          }
      }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoHandler" {
            if let dict = message.body as? [String: Any],
               let state = dict["state"] as? String {
                print("Video state changed: \(state)")
                if state == "play" {
                    stopMonitoringPlayState()
                    activityIndicator?.stopAnimating()
                    activityIndicator?.removeFromSuperview()
                    if let videoUrlString = dict["url"] as? String,
                       let videoUrl = URL(string: videoUrlString) {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
                                self.castVideoToGoogleCast(videoURL: videoUrl)
                                self.dismiss(animated: true, completion: nil)
                            } else {
                                let goGoAnimeMethod = UserDefaults.standard.string(forKey: "GoGoAnimeMethod") ?? "Experimental"
                                
                                switch goGoAnimeMethod {
                                case "Stable":
                                    self.playVideoInAVPlayer(url: videoUrl)
                                case "Experimental":
                                    self.animeDetailsViewController?.playVideo(sourceURL: videoUrl, cell: self.cell, fullURL: self.fullURL)
                                    self.dismiss(animated: true, completion: nil)
                                default:
                                    self.animeDetailsViewController?.playVideo(sourceURL: videoUrl, cell: self.cell, fullURL: self.fullURL)
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else if state == "pause" || state == "complete" || state == "error" {
                    isVideoPlaying = false
                    startMonitoringPlayState(interval: 2.0)
                }
            }
        }
    }

    private func castVideoToGoogleCast(videoURL: URL) {
        DispatchQueue.main.async {
            let metadata = GCKMediaMetadata(metadataType: .movie)
            
            if UserDefaults.standard.bool(forKey: "fullTitleCast") {
                if let animeTitle = self.animeDetailsViewController?.animeTitle {
                    metadata.setString(animeTitle, forKey: kGCKMetadataKeyTitle)
                } else {
                    print("Error: Anime title is missing.")
                }
            } else {
                let episodeNumber = (self.animeDetailsViewController?.currentEpisodeIndex ?? -1) + 1
                metadata.setString("Episode \(episodeNumber)", forKey: kGCKMetadataKeyTitle)
            }
            
            if UserDefaults.standard.bool(forKey: "animeImageCast") {
                if let imageURL = URL(string: self.animeDetailsViewController?.imageUrl ?? "") {
                    metadata.addImage(GCKImage(url: imageURL, width: 480, height: 720))
                } else {
                    print("Error: Anime image URL is missing or invalid.")
                }
            }
            
            let mediaInformation = GCKMediaInformation(contentID: videoURL.absoluteString, streamType: .buffered, contentType: "application/x-mpegURL", metadata: metadata, streamDuration: 0, mediaTracks: nil, textTrackStyle: nil, customData: nil)
            
            if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
                remoteMediaClient.loadMedia(mediaInformation)
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

        self.playerViewController = playerViewController

        player.play()
        isVideoPlaying = true
    }

     override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
         stopAndCleanUp()
     }

     private func stopAndCleanUp() {
         playerViewController?.player?.pause()
         playerViewController?.player?.replaceCurrentItem(with: nil)
         playerViewController?.player = nil

         playerViewController?.willMove(toParent: nil)
         playerViewController?.view.removeFromSuperview()
         playerViewController?.removeFromParent()
         playerViewController = nil
         
         stopMonitoringPlayState()
         isVideoPlaying = false

         webView?.stopLoading()
         webView?.loadHTMLString("", baseURL: nil)
         webView?.configuration.userContentController.removeAllUserScripts()
         webView?.configuration.userContentController.removeScriptMessageHandler(forName: "videoHandler")

         webView?.removeFromSuperview()
         webView = nil

         loadingObserver?.invalidate()
         loadingObserver = nil
     }

     deinit {
         stopAndCleanUp()
         loadingObserver?.invalidate()
     }
 }
