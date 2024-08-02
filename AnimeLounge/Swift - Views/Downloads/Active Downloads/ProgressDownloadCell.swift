//
//  ProgressDownloadCell.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit

class ProgressDownloadCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.backgroundColor = .quaternarySystemFill
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(progressLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            
            progressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            progressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
            progressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with title: String, progress: Float, progressText: String) {
        titleLabel.text = title
        progressView.progress = progress
        progressLabel.text = progressText
    }
}
