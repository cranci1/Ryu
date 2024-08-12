//
//  ProgressDownloadCell.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit

protocol ProgressDownloadCellDelegate: AnyObject {
    func cancelDownload(for cell: ProgressDownloadCell)
}

class ProgressDownloadCell: UIView {
    weak var delegate: ProgressDownloadCellDelegate?
    
    private let backgroundContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .quaternarySystemFill
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
        setupContextMenuInteraction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        addSubview(backgroundContentView)
        backgroundContentView.addSubview(titleLabel)
        backgroundContentView.addSubview(progressView)
        backgroundContentView.addSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            backgroundContentView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backgroundContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            backgroundContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            backgroundContentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            titleLabel.topAnchor.constraint(equalTo: backgroundContentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor, constant: -12),
            
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor, constant: -12),
            
            percentageLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            percentageLabel.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor, constant: -12),
            percentageLabel.bottomAnchor.constraint(equalTo: backgroundContentView.bottomAnchor, constant: -12),
            
            heightAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])
    }
    
    private func setupContextMenuInteraction() {
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
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

extension ProgressDownloadCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copyTitleAction = UIAction(title: "Copy Link", image: UIImage(systemName: "paperclip")) { _ in
                UIPasteboard.general.string = self.titleLabel.text
            }
            
            let cancelDownloadAction = UIAction(title: "Cancel Download", image: UIImage(systemName: "xmark.circle")) { _ in
                self.delegate?.cancelDownload(for: self)
            }
            
            return UIMenu(title: "", children: [copyTitleAction, cancelDownloadAction])
        }
    }
}
