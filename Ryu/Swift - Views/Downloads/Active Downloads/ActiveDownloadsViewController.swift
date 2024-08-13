//
//  ActiveDownloadsViewController.swift
//  Ryu
//
//  Created by Francesco on 01/08/24.
//

import UIKit

class ActiveDownloadsViewController: UIViewController, ProgressDownloadCellDelegate {
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
        let activeDownloads = DownloadManager.shared.getActiveDownloads()
        downloads = activeDownloads.map { (title: $0.key, progress: $0.value) }
        updateDownloadViews()
    }

    private func updateDownloadViews() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            for download in self.downloads {
                let downloadView = ProgressDownloadCell()
                downloadView.configure(with: download.title, progress: download.progress)
                downloadView.delegate = self
                self.stackView.addArrangedSubview(downloadView)
            }

            self.updateEmptyState()
        }
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !downloads.isEmpty
        scrollView.isHidden = downloads.isEmpty
    }
    
    private func updateProgress() {
        let activeDownloads = DownloadManager.shared.getActiveDownloads()
        let newDownloads = activeDownloads.map { (title: $0.key, progress: $0.value) }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for (index, download) in newDownloads.enumerated() {
                if index < self.stackView.arrangedSubviews.count,
                   let downloadView = self.stackView.arrangedSubviews[index] as? ProgressDownloadCell {
                    downloadView.updateProgress(download.progress)
                }
            }
            
            if newDownloads.count != self.stackView.arrangedSubviews.count {
                self.downloads = newDownloads
                self.updateDownloadViews()
            } else {
                self.downloads = newDownloads
            }
        }
    }

    private func startProgressUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    func cancelDownload(for cell: ProgressDownloadCell) {
        guard let index = stackView.arrangedSubviews.firstIndex(of: cell) else { return }
        let download = downloads[index]
        
        DownloadManager.shared.cancelDownload(for: download.title)
        
        downloads.remove(at: index)
        updateDownloadViews()
    }
}
