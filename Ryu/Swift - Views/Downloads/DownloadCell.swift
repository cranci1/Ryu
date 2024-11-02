//
//  DownloadCell.swift
//  Ryu
//
//  Created by Francesco on 16/07/24.
//

import UIKit

class DownloadCell: UITableViewCell {
    let playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        imageView.tintColor = .systemTeal
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubviews()
        setupConstraints()
        setupAppearance()
    }
    
    private func addSubviews() {
        contentView.addSubview(playImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(fileSizeLabel)
        contentView.addSubview(chevronImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 40),
            playImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: playImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            fileSizeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            fileSizeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupAppearance() {
        contentView.backgroundColor = .systemGray5
        backgroundColor = .systemGray5
        selectionStyle = .none
    }
}
