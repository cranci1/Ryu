//
//  CustomPlayer.swift
//  tests
//
//  Created by Francesco on 24/08/24.
//

import UIKit
import AVKit
import AVFoundation

class CustomVideoPlayerView: UIView, AVPictureInPictureControllerDelegate {
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isControlsVisible = true
    private var hideControlsTimer: Timer?
    private var baseURL: URL?
    private var qualities: [(String, String)] = []
    private var currentQualityIndex = 0
    private var timeObserverToken: Any?
    private var isSeekingAllowed = false
    private var blurEffectView: UIVisualEffectView?
    private var pipController: AVPictureInPictureController?
    private var isSpeedIndicatorVisible = false
    private var videoTitle: String = ""
    private var originalBrightness: CGFloat = UIScreen.main.brightness
    private var isFullBrightness = false
    
    private lazy var playPauseButton: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.fill")
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playPauseButtonTapped))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    private lazy var rewindButton: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "gobackward.10"))
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rewindButtonTapped))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    private lazy var forwardButton: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "goforward.10"))
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(forwardButtonTapped))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    private lazy var playerProgress: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .white
        progress.trackTintColor = .gray
        progress.translatesAutoresizingMaskIntoConstraints = false
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleProgressPan(_:)))
        progress.addGestureRecognizer(panGesture)
        progress.isUserInteractionEnabled = true
        
        return progress
    }()
    
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private lazy var controlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gear"), for: .normal)
        button.tintColor = .white
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var speedIndicatorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var speedIndicatorBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    private lazy var speedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "speedometer"), for: .normal)
        button.tintColor = .white
        button.showsMenuAsPrimaryAction = true
        button.addTarget(self, action: #selector(speedButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "forward.end"), for: .normal)
        button.tintColor = .white
        button.showsMenuAsPrimaryAction = true
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dismissButton: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "xmark"))
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissButtonTapped))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    private lazy var pipButton: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "pip.enter"))
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pipButtonTapped))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayer()
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer!)
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.updateTimeLabels()
            self?.updatePlayPauseButton()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
            pipController?.delegate = self
        }
    }
    
    private func setupUI() {
        addSubview(speedIndicatorBackgroundView)
        addSubview(speedIndicatorLabel)
        addSubview(controlsContainerView)
        controlsContainerView.addSubview(playPauseButton)
        controlsContainerView.addSubview(rewindButton)
        controlsContainerView.addSubview(forwardButton)
        controlsContainerView.addSubview(playerProgress)
        controlsContainerView.addSubview(currentTimeLabel)
        controlsContainerView.addSubview(totalTimeLabel)
        controlsContainerView.addSubview(settingsButton)
        controlsContainerView.addSubview(speedButton)
        controlsContainerView.addSubview(nextButton)
        controlsContainerView.addSubview(titleLabel)
        controlsContainerView.addSubview(dismissButton)
        controlsContainerView.addSubview(pipButton)
        
        speedIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        speedIndicatorBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        speedButton.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        rewindButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        playerProgress.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            speedIndicatorLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            speedIndicatorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            speedIndicatorBackgroundView.centerXAnchor.constraint(equalTo: speedIndicatorLabel.centerXAnchor),
            speedIndicatorBackgroundView.centerYAnchor.constraint(equalTo: speedIndicatorLabel.centerYAnchor),
            speedIndicatorBackgroundView.widthAnchor.constraint(equalTo: speedIndicatorLabel.widthAnchor, constant: 20),
            speedIndicatorBackgroundView.heightAnchor.constraint(equalTo: speedIndicatorLabel.heightAnchor, constant: 10),
            
            controlsContainerView.topAnchor.constraint(equalTo: topAnchor),
            controlsContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlsContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: playerProgress.topAnchor, constant: -10),
            titleLabel.trailingAnchor.constraint(equalTo: speedButton.leadingAnchor),
            
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 45),
            playPauseButton.heightAnchor.constraint(equalToConstant: 50),
            
            rewindButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -20),
            rewindButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            rewindButton.widthAnchor.constraint(equalToConstant: 30),
            rewindButton.heightAnchor.constraint(equalToConstant: 30),
            
            forwardButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 20),
            forwardButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 30),
            forwardButton.heightAnchor.constraint(equalToConstant: 30),
            
            playerProgress.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 20),
            playerProgress.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -20),
            playerProgress.bottomAnchor.constraint(equalTo: currentTimeLabel.topAnchor, constant: -5),
            playerProgress.heightAnchor.constraint(equalToConstant: 8),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            currentTimeLabel.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -10),
            
            totalTimeLabel.trailingAnchor.constraint(equalTo: playerProgress.trailingAnchor),
            totalTimeLabel.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -10),
            
            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -5),
            
            speedButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            speedButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -5),
            
            nextButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: totalTimeLabel.trailingAnchor),
            
            dismissButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),
            
            pipButton.centerYAnchor.constraint(equalTo: dismissButton.centerYAnchor),
            pipButton.leadingAnchor.constraint(equalTo: dismissButton.trailingAnchor, constant: 10),
            pipButton.widthAnchor.constraint(equalToConstant: 35),
            pipButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
    
    func setVideo(url: URL, title: String) {
        self.videoTitle = title
        titleLabel.text = title
        self.baseURL = url.deletingLastPathComponent()
        
        if url.pathExtension == "m3u8" {
            parseM3U8(url: url) { [weak self] in
                guard let self = self else { return }
                
                if let highestQualityIndex = self.qualities.indices.last {
                    self.setQuality(index: highestQualityIndex)
                }
                
                self.updateSettingsMenu()
            }
        } else {
            let playerItem = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: playerItem)
            qualities.removeAll()
            updateSettingsMenu()
        }
    }
    
    func play() {
        player?.play()
        updatePlayPauseButton()
    }
    
    func pause() {
        player?.pause()
        updatePlayPauseButton()
    }
    
    private func parseM3U8(url: URL, completion: @escaping () -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                print("Failed to load m3u8 file")
                return
            }
            
            let lines = content.components(separatedBy: .newlines)
            var qualities: [(String, String)] = []
            
            for (index, line) in lines.enumerated() {
                if line.contains("#EXT-X-STREAM-INF") {
                    if let resolutionPart = line.components(separatedBy: "RESOLUTION=").last?.components(separatedBy: ",").first,
                       let height = resolutionPart.components(separatedBy: "x").last,
                       let qualityNumber = ["1080", "720", "480", "360"].first(where: { height.hasPrefix($0) }),
                       index + 1 < lines.count {
                        let filename = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let qualityWithP = "\(qualityNumber)p"
                        qualities.append((qualityWithP, filename))
                    }
                }
            }
            
            qualities.sort { $0.0 > $1.0 }
            
            DispatchQueue.main.async {
                self?.qualities = qualities
                completion()
            }
        }.resume()
    }
    
    private func setQuality(index: Int) {
        guard index < qualities.count else { return }
        
        currentQualityIndex = index
        let (name, filename) = qualities[index]
        
        guard let baseURL = baseURL else { return }
        let fullURL = baseURL.appendingPathComponent(filename)
        
        let currentTime = player?.currentTime()
        let wasPlaying = player?.rate != 0
        
        let playerItem = AVPlayerItem(url: fullURL)
        player?.replaceCurrentItem(with: playerItem)
        
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let time = currentTime, time.isValid && !time.seconds.isNaN {
                self?.player?.seek(to: time) { _ in
                    if wasPlaying {
                        self?.player?.play()
                    }
                }
            }
            
            self?.updateTimeLabels()
            self?.updatePlayPauseButton()
            self?.updateSettingsMenu()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
            if playerItem.status == .readyToPlay {
                isSeekingAllowed = true
                playerItem.removeObserver(self, forKeyPath: "status")
                updateSettingsMenu()
            }
        }
    }
    
    private func updatePlayPauseButton() {
        let isPlaying = player?.rate != 0
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.image = UIImage(systemName: imageName)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        guard !timeInterval.isNaN && timeInterval.isFinite else {
            return "00:00"
        }
        
        let totalSeconds = Int(max(0, timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func updateTimeLabels() {
        guard let currentItem = player?.currentItem else { return }
        
        let currentTime = CMTimeGetSeconds(player?.currentTime() ?? .zero)
        let duration = CMTimeGetSeconds(currentItem.duration)
        
        currentTimeLabel.text = timeString(from: currentTime)
        totalTimeLabel.text = timeString(from: duration)
        
        if duration > 0 {
            playerProgress.progress = Float(max(0, min(currentTime / duration, 1)))
        } else {
            playerProgress.progress = 0
        }
    }
    
    private func showControls() {
        isControlsVisible = true
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 1
        }
        resetHideControlsTimer()
    }
    
    private func hideControls() {
        isControlsVisible = false
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 0
        }
    }
    
    private func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    @objc private func playPauseButtonTapped() {
        if player?.rate == 0 {
            player?.play()
        } else {
            player?.pause()
        }
        updatePlayPauseButton()
        resetHideControlsTimer()
    }
    
    @objc private func rewindButtonTapped() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player?.seek(to: newTime)
        resetHideControlsTimer()
    }
    
    @objc private func forwardButtonTapped() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player?.seek(to: newTime)
        resetHideControlsTimer()
    }
    
    @objc private func handleProgressPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: playerProgress)
        let progress = location.x / playerProgress.bounds.width
        
        switch gesture.state {
        case .began, .changed:
            playerProgress.progress = Float(progress)
        case .ended:
            guard let duration = player?.currentItem?.duration else { return }
            let seekTime = CMTime(seconds: Double(progress) * CMTimeGetSeconds(duration), preferredTimescale: 1)
            player?.seek(to: seekTime)
        default:
            break
        }
    }
    
    @objc private func handleTap() {
        if isControlsVisible {
            hideControls()
        } else {
            showControls()
        }
    }
    
    @objc private func speedButtonTapped() {
        updateSpeedMenu()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            player?.rate = 2.0
            speedIndicatorLabel.text = "2x Speed"
            speedIndicatorLabel.isHidden = false
            speedIndicatorBackgroundView.isHidden = false
        } else if gesture.state == .ended {
            player?.rate = 1.0
            speedIndicatorLabel.isHidden = true
            speedIndicatorBackgroundView.isHidden = true
        }
        
        updateSpeedMenu()
    }
    
    @objc private func nextButtonTapped() {
    }
    
    private func updateSpeedMenu() {
        let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        let currentRate = player?.rate ?? 1.0
        
        let speedMenuItems = speedOptions.map { speed in
            UIAction(title: "\(speed)x", state: (currentRate == speed) ? .on : .off) { [weak self] _ in
                self?.player?.rate = speed
                self?.speedIndicatorLabel.text = "\(speed)x Speed"
                self?.speedIndicatorLabel.isHidden = (speed == 1.0)
                self?.speedIndicatorBackgroundView.isHidden = (speed == 1.0)
                self?.updateSpeedMenu()
            }
        }
        
        let speedMenu = UIMenu(title: "Select Speed", children: speedMenuItems)
        speedButton.menu = speedMenu
    }
    
    private func updateSettingsMenu() {
        var menuItems: [UIMenuElement] = []
        
        if !qualities.isEmpty {
            let qualityItems = qualities.enumerated().map { (index, quality) in
                UIAction(title: quality.0, state: index == currentQualityIndex ? .on : .off) { [weak self] _ in
                    self?.setQuality(index: index)
                }
            }
            let qualitySubmenu = UIMenu(title: "Quality", image: UIImage(systemName: "rectangle.3.offgrid"), children: qualityItems)
            menuItems.append(qualitySubmenu)
        }
        
        let aspectRatioOptions = ["Fit", "Fill"]
        let currentGravity = playerLayer?.videoGravity ?? .resizeAspect
        let aspectRatioItems = aspectRatioOptions.map { option in
            UIAction(title: option, state: (option == "Fit" && currentGravity == .resizeAspect) || (option == "Fill" && currentGravity == .resizeAspectFill) ? .on : .off) { [weak self] _ in
                self?.playerLayer?.videoGravity = option == "Fit" ? .resizeAspect : .resizeAspectFill
                self?.updateSettingsMenu()
            }
        }
        let aspectRatioSubmenu = UIMenu(title: "Aspect Ratio", image: UIImage(systemName: "rectangle.arrowtriangle.2.outward"), children: aspectRatioItems)
        menuItems.append(aspectRatioSubmenu)
        
        let brightnessAction = UIAction(title: "Full Brightness", image: UIImage(systemName: "sun.max"), state: isFullBrightness ? .on : .off) { [weak self] _ in
            self?.toggleFullBrightness()
        }
        menuItems.append(brightnessAction)
        
        let mainMenu = UIMenu(title: "Settings", children: menuItems)
        settingsButton.menu = mainMenu
    }
    
    private func toggleFullBrightness() {
        isFullBrightness.toggle()
        if isFullBrightness {
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        } else {
            UIScreen.main.brightness = originalBrightness
        }
        updateSettingsMenu()
    }
    
    private func updateSpeedIndicator(speed: Float) {
        speedIndicatorLabel.text = "\(speed)x Speed"
        speedIndicatorLabel.isHidden = (speed == 1.0)
        speedIndicatorBackgroundView.isHidden = (speed == 1.0)
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.pause()
        updatePlayPauseButton()
        
        if isFullBrightness {
            UIScreen.main.brightness = originalBrightness
            isFullBrightness = false
            updateSettingsMenu()
        }
    }
    
    @objc private func dismissButtonTapped() {
        findViewController()?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func pipButtonTapped() {
        if let pipController = pipController {
            if pipController.isPictureInPictureActive {
                pipController.stopPictureInPicture()
            } else {
                pipController.startPictureInPicture()
            }
        }
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
