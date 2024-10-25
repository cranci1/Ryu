//
//  SynopsisCell.swift
//  Ryu
//
//  Created by Francesco on 01/08/24.
//

import UIKit

protocol SynopsisCellDelegate: AnyObject {
    func synopsisCellDidToggleExpansion(_ cell: SynopsisCell)
}

class SynopsisCell: UITableViewCell {
    private let synopsisLabel = UILabel()
    private let synopsyLabel = UILabel()
    private let toggleButton = UIButton()
    
    weak var delegate: SynopsisCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .secondarySystemBackground
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(synopsisLabel)
        contentView.addSubview(toggleButton)
        contentView.addSubview(synopsyLabel)
        
        synopsyLabel.text = "Synopsis"
        synopsyLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        synopsyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        synopsisLabel.numberOfLines = 4
        synopsisLabel.font = UIFont.systemFont(ofSize: 14)
        synopsisLabel.translatesAutoresizingMaskIntoConstraints = false
        
        toggleButton.setTitleColor(.systemOrange, for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        
        NSLayoutConstraint.activate([
            synopsyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            synopsyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            
            synopsisLabel.topAnchor.constraint(equalTo: synopsyLabel.bottomAnchor, constant: 5),
            synopsisLabel.leadingAnchor.constraint(equalTo: synopsyLabel.leadingAnchor),
            synopsisLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            synopsisLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            toggleButton.centerYAnchor.constraint(equalTo: synopsyLabel.centerYAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
        ])
    }
    
    func configure(synopsis: String, isExpanded: Bool) {
        synopsisLabel.text = synopsis
        synopsisLabel.numberOfLines = isExpanded ? 0 : 4
        toggleButton.setTitle(isExpanded ? "Less" : "More", for: .normal)
        
        let maxLabelSize = CGSize(width: contentView.frame.width - 30, height: CGFloat.greatestFiniteMagnitude)
        let textHeight = synopsis.boundingRect(with: maxLabelSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font:synopsisLabel.font!], context: nil).height
        
        let lineHeight = synopsisLabel.font.lineHeight
        let numberOfLines = Int(ceil(textHeight / lineHeight))
        
        toggleButton.isHidden = numberOfLines <= 4
    }
    
    @objc private func toggleButtonTapped() {
        delegate?.synopsisCellDidToggleExpansion(self)
    }
}
