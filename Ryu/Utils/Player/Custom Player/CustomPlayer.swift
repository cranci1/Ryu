//
//  CustomPlayer.swift
//  tests
//
//  Created by Francesco on 24/08/24.
//

import UIKit
import AVKit
import MediaPlayer
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
    private var subtitlesURL: URL?
    private var originalBrightness: CGFloat = UIScreen.main.brightness
    private var isFullBrightness = false
    private var cell: EpisodeCell
    private var fullURL: String
    private var hasSentUpdate = false
    private var animeDetailsViewController: AnimeDetailViewController?
    
    private var skipButtons: [UIButton] = []
    private var skipIntervalViews: [UIView] = []
    private var skipIntervals: [(String, TimeInterval, TimeInterval, String)] = []
    private var autoSkipTimer: Timer?
    
    private var hasVotedForSkipTimes = false
    private var hasSkippedIntro = false
    private var hasSkippedOutro = false
    
    private var isSeeking = false
    private var seekThumbWidthConstraint: NSLayoutConstraint?
    private var seekThumbCenterXConstraint: NSLayoutConstraint?
    
    private var subtitles: [SubtitleCue] = []
    private var subtitleTimer: Timer?
    private var subtitleFontSize: CGFloat = 18
    private var subtitleColor: UIColor = .white
    private var subtitleBorderWidth: CGFloat = 1
    private var subtitleBorderColor: UIColor = .black
    private var areSubtitlesHidden = false
    
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
    
    private lazy var progressBarContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var playerProgress: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .white
        progress.trackTintColor = .gray
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private lazy var seekThumb: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var episodeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
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
    
    private lazy var subtitlesLabel: UILabel = {
        let label = UILabel()
        label.textColor = subtitleColor
        label.font = UIFont.systemFont(ofSize: subtitleFontSize, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.layer.shadowColor = subtitleBorderColor.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 0)
        label.layer.shadowOpacity = 1
        label.layer.shadowRadius = subtitleBorderWidth
        label.layer.masksToBounds = false
        return label
    }()
    
    private lazy var airplayButton: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "airplayvideo"))
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(airplayButtonTapped))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    init(frame: CGRect, cell: EpisodeCell, fullURL: String) {
        self.cell = cell
        self.fullURL = fullURL
        super.init(frame: frame)
        setupPlayer()
        setupUI()
        setupGestures()
        updateSubtitleAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
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
        addSubview(subtitlesLabel)
        addSubview(progressBarContainer)
        progressBarContainer.addSubview(playerProgress)
        progressBarContainer.addSubview(seekThumb)
        controlsContainerView.addSubview(playPauseButton)
        controlsContainerView.addSubview(rewindButton)
        controlsContainerView.addSubview(forwardButton)
        controlsContainerView.addSubview(playerProgress)
        controlsContainerView.addSubview(currentTimeLabel)
        controlsContainerView.addSubview(totalTimeLabel)
        controlsContainerView.addSubview(settingsButton)
        controlsContainerView.addSubview(speedButton)
        controlsContainerView.addSubview(titleLabel)
        controlsContainerView.addSubview(dismissButton)
        controlsContainerView.addSubview(pipButton)
        controlsContainerView.addSubview(episodeLabel)
        controlsContainerView.addSubview(airplayButton)
        
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
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        subtitlesLabel.translatesAutoresizingMaskIntoConstraints = false
        episodeLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBarContainer.translatesAutoresizingMaskIntoConstraints = false
        airplayButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            speedIndicatorLabel.centerYAnchor.constraint(equalTo: dismissButton.centerYAnchor, constant: -10),
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
            titleLabel.bottomAnchor.constraint(equalTo: playerProgress.topAnchor, constant: -6),
            titleLabel.trailingAnchor.constraint(equalTo: speedButton.leadingAnchor),
            
            episodeLabel.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            episodeLabel.bottomAnchor.constraint(equalTo: titleLabel.topAnchor),
            
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 50),
            playPauseButton.heightAnchor.constraint(equalToConstant: 55),
            
            rewindButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -80),
            rewindButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            rewindButton.widthAnchor.constraint(equalToConstant: 30),
            rewindButton.heightAnchor.constraint(equalToConstant: 30),
            
            forwardButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 80),
            forwardButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 30),
            forwardButton.heightAnchor.constraint(equalToConstant: 30),
            
            progressBarContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBarContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBarContainer.bottomAnchor.constraint(equalTo: currentTimeLabel.topAnchor),
            progressBarContainer.heightAnchor.constraint(equalToConstant: 17),
            
            playerProgress.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 20),
            playerProgress.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -20),
            playerProgress.bottomAnchor.constraint(equalTo: currentTimeLabel.topAnchor, constant: -5),
            playerProgress.heightAnchor.constraint(equalToConstant: 8),
            
            seekThumb.centerYAnchor.constraint(equalTo: playerProgress.centerYAnchor),
            seekThumb.heightAnchor.constraint(equalToConstant: 16),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            currentTimeLabel.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -30),
            
            totalTimeLabel.trailingAnchor.constraint(equalTo: playerProgress.trailingAnchor),
            totalTimeLabel.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -30),
            
            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: playerProgress.trailingAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            
            speedButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            speedButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -10),
            speedButton.widthAnchor.constraint(equalToConstant: 30),
            
            dismissButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            dismissButton.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 25),
            dismissButton.heightAnchor.constraint(equalToConstant: 25),
            
            pipButton.centerYAnchor.constraint(equalTo: dismissButton.centerYAnchor),
            pipButton.leadingAnchor.constraint(equalTo: dismissButton.trailingAnchor, constant: 20),
            pipButton.widthAnchor.constraint(equalToConstant: 30),
            pipButton.heightAnchor.constraint(equalToConstant: 25),
            
            airplayButton.centerYAnchor.constraint(equalTo: dismissButton.centerYAnchor),
            airplayButton.leadingAnchor.constraint(equalTo: pipButton.trailingAnchor, constant: 20),
            airplayButton.widthAnchor.constraint(equalToConstant: 25),
            airplayButton.heightAnchor.constraint(equalToConstant: 25),
            
            subtitlesLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitlesLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let episodeNumber = Int(self.cell.episodeNumber) ?? 0
        episodeLabel.text = "Episode " + String(episodeNumber)
        
        seekThumbWidthConstraint = seekThumb.widthAnchor.constraint(equalToConstant: 16)
        seekThumbCenterXConstraint = seekThumb.centerXAnchor.constraint(equalTo: playerProgress.leadingAnchor)
        seekThumbWidthConstraint?.isActive = true
        seekThumbCenterXConstraint?.isActive = true
        
        hideSeekThumb()
    }
    
    private func updateSubtitleAppearance() {
        subtitlesLabel.font = UIFont.systemFont(ofSize: subtitleFontSize, weight: .bold)
        subtitlesLabel.textColor = subtitleColor
        subtitlesLabel.layer.shadowColor = subtitleBorderColor.cgColor
        subtitlesLabel.layer.shadowRadius = subtitleBorderWidth
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleProgressPan(_:)))
        progressBarContainer.addGestureRecognizer(panGesture)
        
        let tap2Gesture = UITapGestureRecognizer(target: self, action: #selector(handleProgressTap(_:)))
        progressBarContainer.addGestureRecognizer(tap2Gesture)
    }
    
    @objc private func airplayButtonTapped() {
        let rect = CGRect(x: -100, y: 0, width: 0, height: 0)
        let airplayVolume = MPVolumeView(frame: rect)
        airplayVolume.showsVolumeSlider = false
        self.addSubview(airplayVolume)
        for view: UIView in airplayVolume.subviews {
            if let button = view as? UIButton {
                button.sendActions(for: .touchUpInside)
                break
            }
        }
        airplayVolume.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
        updateProgressBarWithSkipIntervals()
    }
    
    func setVideo(url: URL, title: String, subURL: URL? = nil, cell: EpisodeCell, fullURL: String) {
        self.videoTitle = title
        titleLabel.text = title
        self.baseURL = url.deletingLastPathComponent()
        self.subtitlesURL = subURL
        self.cell = cell
        self.fullURL = fullURL
        
        let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
        
        if url.pathExtension == "m3u8" {
            parseM3U8(url: url) { [weak self] in
                guard let self = self else { return }
                
                if let highestQualityIndex = self.qualities.indices.last {
                    self.setQuality(index: highestQualityIndex)
                    
                    if lastPlayedTime > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.player?.seek(to: CMTime(seconds: lastPlayedTime, preferredTimescale: 1))
                        }
                    }
                }
                
                self.updateSettingsMenu()
            }
        } else {
            let playerItem = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: playerItem)
            qualities.removeAll()
            updateSettingsMenu()
            
            if lastPlayedTime > 0 {
                player?.seek(to: CMTime(seconds: lastPlayedTime, preferredTimescale: 1))
            }
        }
        
        if let subtitlesURL = subtitlesURL {
            loadSubtitles(from: subtitlesURL)
            subtitleTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSubtitle), userInfo: nil, repeats: true)
            subtitlesLabel.isHidden = false
        } else {
            subtitles.removeAll()
            subtitlesLabel.isHidden = true
            subtitleTimer?.invalidate()
            subtitleTimer = nil
        }
        
        addPeriodicTimeObserver(fullURL: fullURL, cell: cell)
        resetSkipFlags()
        skipIntervals.removeAll()
        removeSkipIntervalViews()
        
        fetchAnimeID(title: cleanTitle(title)) { [weak self] anilistID in
            self?.fetchMALID(anilistID: anilistID) { malID in
                guard let malID = malID else { return }
                let episodeNumber = Int(cell.episodeNumber) ?? 1
                self?.fetchSkipTimes(malID: malID, episodeNumber: episodeNumber) { skipTimes in
                    DispatchQueue.main.async {
                        self?.skipIntervals = skipTimes
                        self?.updateSkipButtons()
                        self?.setupSkipButtonUpdates()
                    }
                }
            }
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
    
    private func addPeriodicTimeObserver(fullURL: String, cell: EpisodeCell) {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let currentItem = self.player?.currentItem,
                  currentItem.duration.seconds.isFinite else {
                      return
                  }
            
            let currentTime = time.seconds
            let duration = currentItem.duration.seconds
            let progress = currentTime / duration
            let remainingTime = duration - currentTime
            
            self.cell.updatePlaybackProgress(progress: Float(progress), remainingTime: remainingTime)
            
            UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(fullURL)")
            UserDefaults.standard.set(duration, forKey: "totalTime_\(fullURL)")
            
            let episodeNumber = Int(self.cell.episodeNumber) ?? 0
            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
            
            let continueWatchingItem = ContinueWatchingItem(
                animeTitle: self.videoTitle,
                episodeTitle: "Ep. \(episodeNumber)",
                episodeNumber: episodeNumber,
                imageURL: self.animeDetailsViewController?.imageUrl ?? "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg",
                fullURL: fullURL,
                lastPlayedTime: currentTime,
                totalTime: duration,
                source: selectedMediaSource
            )
            ContinueWatchingManager.shared.saveItem(continueWatchingItem)
            
            let shouldSendPushUpdates = UserDefaults.standard.bool(forKey: "sendPushUpdates")
            
            if shouldSendPushUpdates && remainingTime < 120 && !self.hasSentUpdate {
                let cleanedTitle = self.cleanTitle(self.videoTitle)
                
                self.fetchAnimeID(title: cleanedTitle) { animeID in
                    let aniListMutation = AniListMutation()
                    aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: episodeNumber) { result in
                        switch result {
                        case .success():
                            print("Successfully updated anime progress.")
                        case .failure(let error):
                            print("Failed to update anime progress: \(error.localizedDescription)")
                        }
                    }
                    
                    self.hasSentUpdate = true
                }
            }
        }
    }
    
    func fetchAnimeID(title: String, completion: @escaping (Int) -> Void) {
        if let videoTitle = self.videoTitle as String? {
            let customID = UserDefaults.standard.string(forKey: "customAniListID_\(videoTitle)")
            
            if let customID = customID, let id = Int(customID) {
                completion(id)
                return
            }
        }
        
        AnimeService.fetchAnimeID(byTitle: title) { result in
            switch result {
            case .success(let id):
                completion(id)
            case .failure(let error):
                print("Error fetching anime ID: \(error.localizedDescription)")
            }
        }
    }
    
    func cleanTitle(_ title: String) -> String {
        let unwantedStrings = ["(ITA)", "(Dub)", "(Dub ID)", "(Dublado)"]
        var cleanedTitle = title
        
        for unwanted in unwantedStrings {
            cleanedTitle = cleanedTitle.replacingOccurrences(of: unwanted, with: "")
        }
        
        cleanedTitle = cleanedTitle.replacingOccurrences(of: "\"", with: "")
        return cleanedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    @objc private func handleProgressPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: progressBarContainer)
        let progress = max(0, min(1, (location.x - 20) / (progressBarContainer.bounds.width - 40)))
        
        switch gesture.state {
        case .began:
            isSeeking = true
            showSeekThumb()
            updateSeekThumbPosition(progress: CGFloat(progress))
        case .changed:
            updateSeekThumbPosition(progress: CGFloat(progress))
            updateTimeLabels(progress: Double(progress))
        case .ended:
            isSeeking = false
            hideSeekThumb()
            seek(to: progress)
        default:
            break
        }
    }
    
    @objc private func handleProgressTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: progressBarContainer)
        let progress = max(0, min(1, (location.x - 20) / (progressBarContainer.bounds.width - 40)))
        seek(to: progress)
    }
    
    private func showSeekThumb() {
        UIView.animate(withDuration: 0.2) {
            self.seekThumbWidthConstraint?.constant = 16
            self.seekThumb.alpha = 1
            self.layoutIfNeeded()
        }
    }
    
    private func hideSeekThumb() {
        UIView.animate(withDuration: 0.2) {
            self.seekThumbWidthConstraint?.constant = 4
            self.seekThumb.alpha = 0
            self.layoutIfNeeded()
        }
    }
    
    private func updateSeekThumbPosition(progress: CGFloat) {
        let thumbCenterX = playerProgress.frame.width * progress
        seekThumbCenterXConstraint?.constant = thumbCenterX
        layoutIfNeeded()
    }
    
    private func seek(to progress: Double) {
        guard let duration = player?.currentItem?.duration else { return }
        let seekTime = CMTime(seconds: progress * CMTimeGetSeconds(duration), preferredTimescale: 1)
        player?.seek(to: seekTime)
    }
    
    private func updateTimeLabels() {
        guard let currentItem = player?.currentItem,
              let player = player else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let duration = CMTimeGetSeconds(currentItem.duration)
        
        guard duration > 0 else { return }
        
        let progress = currentTime / duration
        updateTimeLabels(progress: progress)
    }
    
    private func updateTimeLabels(progress: Double) {
        guard let duration = player?.currentItem?.duration else { return }
        let currentTime = progress * CMTimeGetSeconds(duration)
        let remainingTime = CMTimeGetSeconds(duration) - currentTime
        
        currentTimeLabel.text = timeString(from: currentTime)
        totalTimeLabel.text = "-" + timeString(from: remainingTime)
        
        playerProgress.progress = Float(progress)
        updateProgressBarWithSkipIntervals()
    }
    
    private func showControls() {
        isControlsVisible = true
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 1
            self.progressBarContainer.alpha = 1
        }
        resetHideControlsTimer()
    }
    
    private func hideControls() {
        if !isSeeking {
            isControlsVisible = false
            UIView.animate(withDuration: 0.3) {
                self.controlsContainerView.alpha = 0
            }
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
            let holdSpeed = UserDefaults.standard.float(forKey: "holdSpeedPlayer")
            player?.rate = holdSpeed
            speedIndicatorLabel.text = String(format: "%.2fx Speed", holdSpeed)
            speedIndicatorLabel.isHidden = false
            speedIndicatorBackgroundView.isHidden = false
        } else if gesture.state == .ended {
            player?.rate = 1.0
            speedIndicatorLabel.isHidden = true
            speedIndicatorBackgroundView.isHidden = true
        }
        
        updateSpeedMenu()
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
        
        if !subtitles.isEmpty {
            let fontSizeOptions: [CGFloat] = [14, 16, 18, 20, 22, 24]
            let fontSizeItems = fontSizeOptions.map { size in
                UIAction(title: "\(Int(size))pt", state: subtitleFontSize == size ? .on : .off) { [weak self] _ in
                    self?.subtitleFontSize = size
                    self?.updateSubtitleAppearance()
                    self?.updateSettingsMenu()
                }
            }
            let fontSizeSubmenu = UIMenu(title: "Font Size", children: fontSizeItems)
            
            let colorOptions: [(String, UIColor)] = [
                ("Yellow", .yellow), ("White", .white), ("Green", .green), ("Red", .red), ("Blue", .blue), ("Black", .black)
            ]
            let colorItems = colorOptions.map { (name, color) in
                UIAction(title: name, state: subtitleColor == color ? .on : .off) { [weak self] _ in
                    self?.subtitleColor = color
                    self?.updateSubtitleAppearance()
                    self?.updateSettingsMenu()
                }
            }
            let colorSubmenu = UIMenu(title: "Color", children: colorItems)
            
            let borderWidthOptions: [CGFloat] = [0, 1, 2, 3, 4, 5]
            let borderWidthItems = borderWidthOptions.map { width in
                UIAction(title: "\(Int(width))pt", state: subtitleBorderWidth == width ? .on : .off) { [weak self] _ in
                    self?.subtitleBorderWidth = width
                    self?.updateSubtitleAppearance()
                    self?.updateSettingsMenu()
                }
            }
            let borderWidthSubmenu = UIMenu(title: "Shadow Intensity", children: borderWidthItems)
            
            let hideSubtitlesAction = UIAction(title: "Hide Subtitles", state: areSubtitlesHidden ? .on : .off) { [weak self] _ in
                self?.toggleSubtitles()
            }
            
            let subtitleSettingsSubmenu = UIMenu(title: "Subtitle Settings", image: UIImage(systemName: "captions.bubble"), children: [
                hideSubtitlesAction,
                fontSizeSubmenu,
                colorSubmenu,
                borderWidthSubmenu
            ])
            menuItems.append(subtitleSettingsSubmenu)
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
    
    private func toggleSubtitles() {
        areSubtitlesHidden.toggle()
        subtitlesLabel.isHidden = areSubtitlesHidden
        updateSettingsMenu()
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
        player?.pause()
        updatePlayPauseButton()
        
        if isFullBrightness {
            UIScreen.main.brightness = originalBrightness
            isFullBrightness = false
            updateSettingsMenu()
        }
        
        showControls()
        
        playerProgress.progress = 1.0
        
        if let duration = player?.currentItem?.duration {
            currentTimeLabel.text = timeString(from: CMTimeGetSeconds(duration))
            totalTimeLabel.text = "-00:00"
        }
        
        if UserDefaults.standard.bool(forKey: "skipFeedbacks") && !hasVotedForSkipTimes {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showSkipVoteAlert()
            }
        }
    }
    
    @objc private func dismissButtonTapped() {
        self.hasSentUpdate = false
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
    
    private func loadSubtitles(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data else { return }
            self.subtitles = SubtitlesLoader.parseVTT(data: data)
        }.resume()
    }
    
    @objc private func updateSubtitle() {
        guard !areSubtitlesHidden, let player = player else { return }
        
        let currentTime = player.currentTime()
        
        for cue in subtitles {
            if CMTimeCompare(currentTime, cue.startTime) >= 0 && CMTimeCompare(currentTime, cue.endTime) <= 0 {
                subtitlesLabel.text = cue.text
                return
            }
        }
        
        subtitlesLabel.text = nil
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

extension CustomVideoPlayerView {
    func fetchMALID(anilistID: Int, completion: @escaping (Int?) -> Void) {
        let urlString = "https://api.ani.zip/mappings?anilist_id=\(anilistID)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let mappings = json["mappings"] as? [String: Any],
                   let malID = mappings["mal_id"] as? Int {
                    completion(malID)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func fetchSkipTimes(malID: Int, episodeNumber: Int, completion: @escaping ([(String, TimeInterval, TimeInterval, String)]) -> Void) {
        let urlString = "https://api.aniskip.com/v1/skip-times/\(malID)/\(episodeNumber)?types=op&types=ed"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    let skipTimes = results.compactMap { result -> (String, TimeInterval, TimeInterval, String)? in
                        guard let interval = result["interval"] as? [String: Double],
                              let startTime = interval["start_time"],
                              let endTime = interval["end_time"],
                              let skipType = result["skip_type"] as? String,
                              let skipId = result["skip_id"] as? String else {
                                  return nil
                              }
                        return (skipType, startTime, endTime, skipId)
                    }
                    completion(skipTimes)
                } else {
                    completion([])
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion([])
            }
        }.resume()
    }
    
    private func updateSkipButtons() {
        for button in skipButtons {
            button.removeFromSuperview()
        }
        skipButtons.removeAll()
        
        for (index, interval) in skipIntervals.enumerated() {
            let button = UIButton(type: .system)
            
            button.setTitle(interval.0 == "op" ? "SKIP INTRO" : "SKIP OUTRO", for: .normal)
            button.backgroundColor = UIColor.white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            
            button.tag = index
            button.addTarget(self, action: #selector(skipButtonTapped(_:)), for: .touchUpInside)
            button.alpha = 0
            
            addSubview(button)
            skipButtons.append(button)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.trailingAnchor.constraint(equalTo: speedButton.leadingAnchor),
                button.topAnchor.constraint(equalTo: settingsButton.bottomAnchor),
                button.widthAnchor.constraint(equalToConstant: 110),
                button.heightAnchor.constraint(equalToConstant: 38)
            ])
        }
    }
    
    @objc private func updateSkipButtonsVisibility() {
        guard let currentTime = player?.currentTime().seconds else { return }
        
        for (index, interval) in skipIntervals.enumerated() {
            let button = skipButtons[index]
            let isWithinInterval = currentTime >= interval.1 && currentTime <= interval.2
            
            UIView.animate(withDuration: 0.3) {
                button.alpha = isWithinInterval ? 1 : 0
            }
            
            if isWithinInterval {
                let shouldAutoSkip: Bool
                var hasSkipped: Bool
                
                if interval.0 == "op" {
                    shouldAutoSkip = UserDefaults.standard.bool(forKey: "autoSkipIntro")
                    hasSkipped = hasSkippedIntro
                } else {
                    shouldAutoSkip = UserDefaults.standard.bool(forKey: "autoSkipOutro")
                    hasSkipped = hasSkippedOutro
                }
                
                if shouldAutoSkip && !hasSkipped {
                    
                    player?.seek(to: CMTime(seconds: interval.2, preferredTimescale: 1))
                    if interval.0 == "op" {
                        hasSkippedIntro = true
                    } else {
                        hasSkippedOutro = true
                    }
                    UIView.animate(withDuration: 0.3) {
                        button.alpha = 0
                    }
                }
            }
        }
    }
    
    func resetSkipFlags() {
        hasSkippedIntro = false
        hasSkippedOutro = false
    }
    
    private func setupSkipButtonUpdates() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.updateSkipButtonsVisibility()
        }
    }
    
    @objc private func skipButtonTapped(_ sender: UIButton) {
        let interval = skipIntervals[sender.tag]
        player?.seek(to: CMTime(seconds: interval.2, preferredTimescale: 1))
        autoSkipTimer?.invalidate()
    }
    
    private func updateProgressBarWithSkipIntervals() {
        removeSkipIntervalViews()
        
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        
        for interval in skipIntervals {
            let startPercentage = CGFloat(interval.1 / duration)
            let endPercentage = CGFloat(interval.2 / duration)
            
            let skipView = UIView()
            skipView.backgroundColor = .systemTeal
            skipView.alpha = 0.5
            
            playerProgress.addSubview(skipView)
            skipIntervalViews.append(skipView)
            
            skipView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                skipView.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor, constant: playerProgress.bounds.width * startPercentage),
                skipView.widthAnchor.constraint(equalToConstant: playerProgress.bounds.width * (endPercentage - startPercentage)),
                skipView.topAnchor.constraint(equalTo: playerProgress.topAnchor),
                skipView.bottomAnchor.constraint(equalTo: playerProgress.bottomAnchor)
            ])
        }
    }
    
    private func removeSkipIntervalViews() {
        for view in skipIntervalViews {
            view.removeFromSuperview()
        }
        skipIntervalViews.removeAll()
    }
    
    private func showSkipVoteAlert() {
        guard let viewController = self.findViewController() else { return }
        
        let alert = UIAlertController(title: "Rate Skip Timestamps", message: "Were the skip timestamps accurate?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Upvote - Good skips", style: .default) { [weak self] _ in
            self?.voteForSkipTimes(voteType: "upvote")
        })
        
        alert.addAction(UIAlertAction(title: "Downvote - Bad skips", style: .default) { [weak self] _ in
            self?.voteForSkipTimes(voteType: "downvote")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        viewController.present(alert, animated: true)
    }
    
    private func voteForSkipTimes(voteType: String) {
        for interval in skipIntervals {
            let skipId = interval.3
            sendVote(skipId: skipId, voteType: voteType)
        }
        hasVotedForSkipTimes = true
    }
    
    private func sendVote(skipId: String, voteType: String) {
        let urlString = "https://api.aniskip.com/v1/skip-times/vote/\(skipId)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let payload = ["vote_type": voteType]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending vote: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Vote sent successfully")
            } else {
                print("Unexpected response from server")
            }
        }.resume()
    }
}
