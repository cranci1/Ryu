//
//  ExternalVideoPlayer3rb.swift
//  AnimeLounge
//
//  Created by Francesco on 08/07/24.
//

import AVKit
import WebKit
import SwiftSoup
import GoogleCast

class ExternalVideoPlayer3rb: UIViewController, GCKRemoteMediaClientListener {
    private let streamURL: String
    private var webView: WKWebView?
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var activityIndicator: UIActivityIndicatorView?
    
    private var progressView: UIProgressView?
    private var progressLabel: UILabel?
    
    private var retryCount = 0
    private let maxRetries = 99
    
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
        setupUI()
        loadInitialURL()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanup()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.secondarySystemBackground
        setupActivityIndicator()
        setupWebView()
        setupProgressUI()
        
        self.progressView?.isHidden = true
        self.progressLabel?.isHidden = true
    }
    
    private func setupProgressUI() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView?.progress = 0.0
        progressView?.trackTintColor = UIColor.gray
        progressView?.progressTintColor = UIColor.systemTeal
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel = UILabel()
        progressLabel?.textColor = .label
        progressLabel?.translatesAutoresizingMaskIntoConstraints = false

        if let progressView = progressView, let progressLabel = progressLabel {
            view.addSubview(progressView)
            view.addSubview(progressLabel)
            
            NSLayoutConstraint.activate([
                progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
                
                progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8)
            ])
        }
    }
    
    private func updateProgress(progress: Float) {
        
        self.progressView?.isHidden = false
        self.progressLabel?.isHidden = false
        
        progressView?.progress = progress
        progressLabel?.text = "Downloaded \(Int(progress * 100))%"
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.color = .label
        activityIndicator?.startAnimating()
        activityIndicator?.center = view.center
        if let activityIndicator = activityIndicator {
            view.addSubview(activityIndicator)
        }
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
    }
    
    private func loadInitialURL() {
        guard let url = URL(string: streamURL) else {
            print("Invalid stream URL")
            return
        }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    private func loadIframeContent(url: URL) {
        let request = URLRequest(url: url)
        webView?.load(request)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.extractVideoSource()
        }
    }
    
    private func extractIframeSource() {
        webView?.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self, let htmlString = result as? String else {
                print("Error getting HTML: \(error?.localizedDescription ?? "Unknown error")")
                self?.retryExtraction()
                return
            }
            
            if let iframeURL = self.extractIframeSourceURL(from: htmlString) {
                print("Iframe src URL found: \(iframeURL.absoluteString)")
                self.loadIframeContent(url: iframeURL)
            } else {
                print("No iframe source found")
                self.retryExtraction()
            }
        }
    }
    
    private func extractVideoSource() {
        webView?.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self, let htmlString = result as? String else {
                print("Error getting HTML: \(error?.localizedDescription ?? "Unknown error")")
                self?.retryExtraction()
                return
            }
            
            if let videoURL = self.extractVideoSourceURL(from: htmlString) {
                print("Video source URL found: \(videoURL.absoluteString)")
                self.playVideo(url: videoURL)
            } else {
                print("No video source found in iframe content")
                self.retryExtraction()
            }
        }
    }
    
    private func extractIframeSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let iframeElement = try doc.select("iframe").first(),
                  let sourceURLString = try iframeElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    private func extractVideoSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let videoElement = try doc.select("video").first(),
                  let sourceURLString = try videoElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            
            let pattern = #"<video[^>]+src="([^"]+)"#
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
                  let urlRange = Range(match.range(at: 1), in: htmlString) else {
                return nil
            }
            
            let urlString = String(htmlString[urlRange])
            return URL(string: urlString)
        }
    }
    
    private func playVideo(url: URL) {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            
            if UserDefaults.standard.bool(forKey: "isToDownload") {
                UserDefaults.standard.set(false, forKey: "isToDownload")
                let downloader = MP4Downloader(url: url)
                self.dismiss(animated: true, completion: nil)
                self.animeDetailsViewController?.showAlert(withTitle: "Download Started", message: "You can view your download in the Library -> Downloads.")
                downloader.startDownload(progress: { progress in
                    DispatchQueue.main.async {
                        print("Download progress: \(progress * 100)%")
                    }
                }) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            self.animeDetailsViewController?.showAlert(withTitle: "Download Completed!", message: "You can find your download in the Library -> Downloads.")
                            self.dismiss(animated: true, completion: nil)
                        }
                    case .failure(let error):
                        print("Download failed with error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.animeDetailsViewController?.showAlert(withTitle: "Download Failed", message: "\(error.localizedDescription)")
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            } else {
                self.playOrCastVideo(url: url)
            }
        }
    }

    private func playOrCastVideo(url: URL) {
        if GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil {
            self.castVideoToGoogleCast(videoURL: url)
            self.dismiss(animated: true, completion: nil)
        } else {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            self.addChild(playerViewController)
            self.view.addSubview(playerViewController.view)
            playerViewController.view.frame = self.view.bounds
            playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            playerViewController.didMove(toParent: self)
            
            player.play()
            
            self.player = player
            self.playerViewController = playerViewController
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
            
            let builder = GCKMediaInformationBuilder(contentURL: videoURL)
            builder.streamType = .buffered
            builder.contentType = "video/mp4"
            builder.metadata = metadata
            
            let mediaInformation = builder.build()
            
            if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
                remoteMediaClient.loadMedia(mediaInformation)
            }
        }
    }
    
    private func retryExtraction() {
        retryCount += 1
        if retryCount < maxRetries {
            print("Retrying extraction (Attempt \(retryCount + 1))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.loadInitialURL()
            }
        } else {
            print("Max retries reached. Unable to find video source.")
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
        
        playerViewController?.willMove(toParent: nil)
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
        
        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
    }
}

extension ExternalVideoPlayer3rb: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString == streamURL {
            extractIframeSource()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
        retryExtraction()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
        retryExtraction()
    }
}
