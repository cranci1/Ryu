//
//  DownloadProgressFloatingView.swift
//  AnimeLounge
//
//  Created by Francesco on 27/07/24.
//

import UIKit
import Kingfisher

class FloatingDownloadView: UIView {
    private let imageView: UIImageView
    private let titleLabel: UILabel
    private let progressView: UIProgressView
    private let percentageLabel: UILabel
    
    init(title: String, imageURL: String) {
        imageView = UIImageView()
        titleLabel = UILabel()
        progressView = UIProgressView(progressViewStyle: .default)
        percentageLabel = UILabel()
        
        super.init(frame: .zero)
        
        setupView()
        setupConstraints()
        
        titleLabel.text = title
        loadImage(from: imageURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.numberOfLines = 2
        
        percentageLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        percentageLabel.textAlignment = .right
        
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(progressView)
        addSubview(percentageLabel)
    }
    
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            progressView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            percentageLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -5)
        ])
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        imageView.kf.setImage(with: url)
    }
    
    func updateProgress(_ progress: Float) {
        DispatchQueue.main.async {
            self.progressView.progress = progress
            self.percentageLabel.text = String(format: "%.0f%%", progress * 100)
        }
    }
}
