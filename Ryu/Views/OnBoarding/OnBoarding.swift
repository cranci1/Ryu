//
//  onBoarding.swift
//  Osmium
//
//  Created by Francesco on 20/11/24.
//

import UIKit

class OnboardingViewController: UIViewController {
    struct OnboardingPage {
        let icon: UIImage?
        let title: String
        let description: String
        let backgroundColor: UIColor
        let showPlatforms: Bool
    }
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .systemTeal
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.backgroundColor = .systemTeal
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip", for: .normal)
        button.setTitleColor(.systemTeal, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let platforms = [
        "AnimeWorld🇮🇹", "GoGoAnime🇺🇸",
        "AnimeHeaven🇺🇸", "AnimeFire🇵🇹",
        "Kuramanime🇮🇩", "JKAnime🇪🇸",
        "Anime3rb🇸🇦", "HiAnime🇺🇸",
        "Anilibria🇷🇺", "AnimeSRBIJA🇭🇷",
        "AniWorld🇩🇪", "TokyoInsider🇺🇸"
    ]
    
    private let pages: [OnboardingPage] = [
        .init(
            icon: UIImage(named: "Icon"),
            title: "Welcome to Ryu",
            description: "A simple way to enjoy and watch anime on iOS with no ADs or distractions.",
            backgroundColor: .systemBackground,
            showPlatforms: false
        ),
        .init(
            icon: UIImage(systemName: "globe"),
            title: "Multi-Platform Support",
            description: "Stream anime from various languages based on the source (Make sure to select the source first):",
            backgroundColor: .systemBackground,
            showPlatforms: true
        ),
        .init(
            icon: UIImage(systemName: "tray"),
            title: "3rd-Party Tracking",
            description: "Seamlessly track your anime progress with AniList and Kitsu integrations. Keep your watchlist updated with the connected platforms.",
            backgroundColor: .systemBackground,
            showPlatforms: false
        ),
        .init(
            icon: UIImage(systemName: "bell.fill"),
            title: "Stay Updated",
            description: "Get real-time notifications for new episodes, recommendations, and anime updates in your interests.",
            backgroundColor: .systemBackground,
            showPlatforms: false
        ),
        .init(
            icon: UIImage(systemName: "lock.shield.fill"),
            title: "Secure & Private",
            description: "Enjoy your favorite anime with top-notch privacy and security features. Your AniList and Kitsu tokens are encrypted in the iPhone Keychaing.",
            backgroundColor: .systemBackground,
            showPlatforms: false
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(continueButton)
        view.addSubview(skipButton)
        
        scrollView.delegate = self
        pageControl.numberOfPages = pages.count
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),
            
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createPlatformsLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemTeal
        label.textAlignment = .center
        return label
    }
    
    private func setupPages() {
        for (index, page) in pages.enumerated() {
            let pageView = UIView(frame: .zero)
            pageView.translatesAutoresizingMaskIntoConstraints = false
            
            let iconImageView = UIImageView(image: page.icon)
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.tintColor = .systemTeal
            
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = page.title
            titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            titleLabel.textAlignment = .center
            
            let descriptionLabel = UILabel()
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            descriptionLabel.text = page.description
            descriptionLabel.font = UIFont.systemFont(ofSize: 16)
            descriptionLabel.textColor = .secondaryLabel
            descriptionLabel.textAlignment = .center
            descriptionLabel.numberOfLines = 0
            
            pageView.addSubview(iconImageView)
            pageView.addSubview(titleLabel)
            pageView.addSubview(descriptionLabel)
            
            var constraints = [
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                pageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                pageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * view.bounds.width),
                
                iconImageView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
                iconImageView.centerYAnchor.constraint(equalTo: pageView.centerYAnchor, constant: -100),
                iconImageView.widthAnchor.constraint(equalToConstant: 100),
                iconImageView.heightAnchor.constraint(equalToConstant: 100),
                
                titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -20),
                
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                descriptionLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 20),
                descriptionLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -20)
            ]
            
            if page.showPlatforms {
                let servicesContainer = UIStackView()
                servicesContainer.translatesAutoresizingMaskIntoConstraints = false
                servicesContainer.axis = .horizontal
                servicesContainer.distribution = .fillEqually
                servicesContainer.spacing = 20
                pageView.addSubview(servicesContainer)
                
                let leftColumn = UIStackView()
                leftColumn.axis = .vertical
                leftColumn.spacing = 12
                leftColumn.distribution = .fillEqually
                
                let rightColumn = UIStackView()
                rightColumn.axis = .vertical
                rightColumn.spacing = 12
                rightColumn.distribution = .fillEqually
                
                for (index, service) in platforms.enumerated() {
                    let serviceLabel = createPlatformsLabel(service)
                    if index % 2 == 0 {
                        leftColumn.addArrangedSubview(serviceLabel)
                    } else {
                        rightColumn.addArrangedSubview(serviceLabel)
                    }
                }
                
                servicesContainer.addArrangedSubview(leftColumn)
                servicesContainer.addArrangedSubview(rightColumn)
                
                constraints.append(contentsOf: [
                    servicesContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
                    servicesContainer.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
                    servicesContainer.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40),
                    servicesContainer.heightAnchor.constraint(lessThanOrEqualTo: pageView.heightAnchor, multiplier: 0.4)
                ])
            }
            
            scrollView.addSubview(pageView)
            NSLayoutConstraint.activate(constraints)
        }
        
        scrollView.contentSize = CGSize(width: view.bounds.width * CGFloat(pages.count), height: scrollView.bounds.height)
    }
    
    @objc private func continueButtonTapped() {
        let currentPage = pageControl.currentPage
        
        if currentPage < pages.count - 1 {
            let nextPage = currentPage + 1
            let offset = CGPoint(x: CGFloat(nextPage) * scrollView.bounds.width, y: 0)
            
            self.scrollView.setContentOffset(offset, animated: false)
            self.pageControl.currentPage = nextPage
            
            continueButton.setTitle(nextPage == pages.count - 1 ? "Start Watching" : "Continue", for: .normal)
        } else {
            completeOnboarding()
        }
    }
    
    @objc private func skipButtonTapped() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss(animated: true, completion: nil)
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = page
        
        continueButton.setTitle(page == pages.count - 1 ? "Start Watching" : "Continue", for: .normal)
    }
}
