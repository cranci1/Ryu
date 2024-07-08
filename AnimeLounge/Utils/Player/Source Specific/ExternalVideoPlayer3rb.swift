//
//  ExternalVideoPlayer3rb.swift
//  AnimeLounge
//
//  Created by Francesco on 08/07/24.
//

import WebKit
import AVKit
import Combine
import SwiftSoup

class ExternalVideoPlayer3rb: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView?
    private var streamURL: String
    private var activityIndicator: UIActivityIndicatorView?
    
    private var retryCount = 0
    private let maxRetries = 999999
    
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

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
        setupWebView()
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

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
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
        
        if let url = URL(string: streamURL) {
            let request = URLRequest(url: url)
            webView?.load(request)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        extractIframeSource()
    }

    private func extractIframeSource() {
        webView?.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self, let htmlString = result as? String else {
                print("Error getting HTML: \(error?.localizedDescription ?? "Unknown error")")
                self?.retryExtraction()
                return
            }
            
            if let iframeURL = self.extractIframeSourceURL(from: htmlString) {
                self.loadIframeContent(url: iframeURL)
            } else {
                print("No iframe source found")
                self.retryExtraction()
            }
        }
    }

    private func loadIframeContent(url: URL) {
        let request = URLRequest(url: url)
        webView?.load(request)
        webView?.navigationDelegate = self
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed to load page: \(error.localizedDescription)")
        retryExtraction()
    }

    private func extractVideoSource() {
        webView?.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self, let htmlString = result as? String else {
                print("Error getting HTML: \(error?.localizedDescription ?? "Unknown error")")
                self?.retryExtraction()
                return
            }
            
            if let videoURL = self.extractVideoSourceURL(from: htmlString) {
                self.playVideo(url: videoURL)
            } else {
                print("No video source found")
                self.retryExtraction()
            }
        }
    }

    private func retryExtraction() {
        retryCount += 1
        if retryCount < maxRetries {
            print("Retrying extraction (Attempt \(retryCount + 1))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.extractIframeSource()
            }
        } else {
            print("Max retries reached. Unable to find video source.")
        }
    }

    private func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        present(playerViewController!, animated: true) {
            self.player?.play()
        }
    }
    
    private func extractVideoSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let videoElement = try doc.select("video").first(),
                  let sourceElement = try videoElement.select("source").first(),
                  let sourceURLString = try sourceElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            
            let mp4Pattern = #"<source src="(.*?)" type="video/mp4">"#
            let m3u8Pattern = #"<source src="(.*?)" type="application/x-mpegURL">"#
            
            if let mp4URL = extractURL(from: htmlString, pattern: mp4Pattern) {
                return mp4URL
            } else if let m3u8URL = extractURL(from: htmlString, pattern: m3u8Pattern) {
                return m3u8URL
            }
            return nil
        }
    }
    
    private func extractURL(from htmlString: String, pattern: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let urlRange = Range(match.range(at: 1), in: htmlString) else {
            return nil
        }
        
        let urlString = String(htmlString[urlRange])
        return URL(string: urlString)
    }
    
    private func extractIframeSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let iframeElement = try doc.select("iframe").first(),
                  let sourceURLString = try iframeElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            print("Iframe src URL: \(sourceURL.absoluteString)")
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerViewController?.player?.pause()
        playerViewController?.player = nil
        playerViewController?.willMove(toParent: nil)
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
    }
}
