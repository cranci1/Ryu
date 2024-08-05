//
//  ProgressDownloadCell.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit

class ProgressDownloadCell: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true

        addSubview(titleLabel)
        addSubview(progressView)
        addSubview(percentageLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            percentageLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            percentageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func configure(with title: String, progress: Float) {
        titleLabel.text = title
        updateProgress(progress)
    }

    func updateProgress(_ progress: Float) {
        progressView.progress = progress
        percentageLabel.text = String(format: "%.0f%%", progress * 100)
    }
}
