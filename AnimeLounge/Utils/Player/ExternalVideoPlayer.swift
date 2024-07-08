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
    private var playerViewController: AVPlayerViewController?
    private var isVideoPlaying = false
    private var streamURL: String
    private var activityIndicator: UIActivityIndicatorView?

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
        case "AnimeFire":
            script = """
            (function() {
                var playButton = document.querySelector('div.play-button');
                if (playButton) {
                    playButton.click();
                    return 'Clicked play button for AnimeFire';
                }
                var video = document.querySelector('video');
                if (video) {
                    if (video.paused) {
                        video.play();
                        return 'Started video playback for AnimeFire';
                    } else {
                        return 'Video is already playing for AnimeFire';
                    }
                }
                return 'No play button or video element found for AnimeFire';
            })();
            """
        case "AnimeToast":
            script = """
            (function() {
                var playButton = document.querySelector('.vjs-big-play-button');
                if (playButton) {
                    playButton.click();
                    return 'Clicked play button for AnimeToast';
                }
                var video = document.querySelector('video');
                if (video) {
                    if (video.paused) {
                        video.play();
                        return 'Started video playback for AnimeToast';
                    } else {
                        return 'Video is already playing for AnimeToast';
                    }
                }
                return 'No play button or video element found for AnimeToast';
            })();
            """
        case "Anime3rb":
            script = """
            (function() {
                var playButton = document.querySelector('button.vjs-big-play-button');
                if (playButton) {
                    playButton.click();
                    return 'Clicked play button for Anime3rb';
                }
                var video = document.querySelector('video');
                if (video) {
                    if (video.paused) {
                        video.play();
                        return 'Started video playback for Anime3rb';
                    } else {
                        return 'Video is already playing for Anime3rb';
                    }
                }
                return 'No play button or video element found for Anime3rb';
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
        case "AnimeFire":
            script = """
            function notifyVideoState(state, videoUrl) {
                window.webkit.messageHandlers.videoHandler.postMessage({state: state, url: videoUrl});
            }

            function setupVideoListeners() {
                var video = document.querySelector('video');
                if (video) {
                    video.addEventListener('play', function() {
                        notifyVideoState('play', video.src);
                    });
                    video.addEventListener('pause', function() { notifyVideoState('pause', null); });
                    video.addEventListener('ended', function() { notifyVideoState('complete', null); });
                    video.addEventListener('error', function() { notifyVideoState('error', null); });
                }
            }

            setupVideoListeners();

            var playButton = document.querySelector('div.play-button');
            if (playButton) {
                playButton.addEventListener('click', function() {
                    setTimeout(setupVideoListeners, 100);
                });
            }

            var video = document.querySelector('video');
            if (video && !video.paused) {
                notifyVideoState('play', video.src);
            }
            """
        case "AnimeToast":
            script = """
            function notifyVideoState(state, videoUrl) {
                window.webkit.messageHandlers.videoHandler.postMessage({state: state, url: videoUrl});
            }

            function setupVideoListeners() {
                var video = document.querySelector('video');
                if (video) {
                    video.addEventListener('play', function() {
                        notifyVideoState('play', video.src);
                    });
                    video.addEventListener('pause', function() { notifyVideoState('pause', null); });
                    video.addEventListener('ended', function() { notifyVideoState('complete', null); });
                    video.addEventListener('error', function() { notifyVideoState('error', null); });
                }
            }

            setupVideoListeners();

            var playButton = document.querySelector('.vjs-big-play-button');
            if (playButton) {
                playButton.addEventListener('click', function() {
                    setTimeout(setupVideoListeners, 100);
                });
            }

            var video = document.querySelector('video');
            if (video && !video.paused) {
                notifyVideoState('play', video.src);
            }
            """
        case "Anime3rb":
            script = """
            function notifyVideoState(state, videoUrl) {
                window.webkit.messageHandlers.videoHandler.postMessage({state: state, url: videoUrl});
            }

            function setupVideoListeners() {
                var video = document.querySelector('video');
                if (video) {
                    video.addEventListener('play', function() {
                        notifyVideoState('play', video.src);
                    });
                    video.addEventListener('pause', function() { notifyVideoState('pause', null); });
                    video.addEventListener('ended', function() { notifyVideoState('complete', null); });
                    video.addEventListener('error', function() { notifyVideoState('error', null); });
                }
            }

            setupVideoListeners();

            var playButton = document.querySelector('button.vjs-big-play-button');
            if (playButton) {
                playButton.addEventListener('click', function() {
                    setTimeout(setupVideoListeners, 100);
                });
            }

            var video = document.querySelector('video');
            if (video && !video.paused) {
                notifyVideoState('play', video.src);
            }
            """
        default:
            script = ""
        }

        webView?.evaluateJavaScript(script, completionHandler: nil)
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopPlayerAndCleanUp()
    }

    private func stopPlayerAndCleanUp() {
        playerViewController?.player?.pause()
        playerViewController?.player = nil

        playerViewController?.willMove(toParent: nil)
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil

        stopMonitoringPlayState()
        isVideoPlaying = false

        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
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

    deinit {
        stopPlayerAndCleanUp()
        loadingObserver?.invalidate()
    }
}
