//
//  ExternalVideoPlayerJK.swift
//  AnimeLounge
//
//  Created by Francesco on 13/07/24.
//

import UIKit
import WebKit
import AVKit

class ExternalVideoPlayerJK: UIViewController, WKNavigationDelegate {
    
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var videoURL: String?
    private var playerViewController: AVPlayerViewController?
    
    init(streamURL: String) {
        super.init(nibName: nil, bundle: nil)
        self.videoURL = streamURL
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemBackground
        
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.isHidden = true
        view.addSubview(webView)
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        if let urlString = videoURL, let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.simulateClickInIframe()
        }
    }
    
    private func simulateClickInIframe() {
        let jsCode = """
        var iframe = document.querySelector('iframe.player_conte');
        var iframeDocument = iframe.contentDocument || iframe.contentWindow.document;
        var videoElement = iframeDocument.querySelector('video');
        var clickEvent = document.createEvent('MouseEvents');
        clickEvent.initMouseEvent('click', true, true, window);
        videoElement.dispatchEvent(clickEvent);
        videoElement.getAttribute('src');
        """
        
        webView.evaluateJavaScript(jsCode) { [weak self] result, error in
            self?.activityIndicator.stopAnimating()
            self?.webView.isHidden = true
            if let videoSrc = result as? String, error == nil {
                self?.playVideo(urlString: videoSrc)
            } else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func playVideo(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        player.play()
        
        present(playerViewController!, animated: true, completion: nil)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopContent()
    }
    
    private func stopContent() {
        playerViewController?.player?.pause()
        playerViewController = nil
        webView?.stopLoading()
        webView = nil
    }
}
