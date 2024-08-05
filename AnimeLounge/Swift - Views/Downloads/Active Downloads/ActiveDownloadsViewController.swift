//
//  ActiveDownloadsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit

class ActiveDownloadsViewController: UIViewController {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No active downloads. You can start one by clicking the download button next to each episode."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var downloads: [(title: String, progress: Float)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        setupViews()
        loadDownloads()
        startProgressUpdateTimer()
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func loadDownloads() {
        downloads = DownloadManager.shared.getActiveDownloads()
        updateDownloadViews()
    }

    private func updateDownloadViews() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for download in downloads {
            let downloadView = ProgressDownloadCell()
            downloadView.configure(with: download.title, progress: download.progress)
            stackView.addArrangedSubview(downloadView)
        }

        updateEmptyState()
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !downloads.isEmpty
        scrollView.isHidden = downloads.isEmpty
    }

    private func startProgressUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func updateProgress() {
        downloads = DownloadManager.shared.getActiveDownloads()
        
        for (index, download) in downloads.enumerated() {
            if let downloadView = stackView.arrangedSubviews[index] as? ProgressDownloadCell {
                downloadView.updateProgress(download.progress)
            }
        }

        if downloads.count != stackView.arrangedSubviews.count {
            updateDownloadViews()
        }
    }
}
