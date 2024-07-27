//
//  FloatingManager.swift
//  AnimeLounge
//
//  Created by Francesco on 27/07/24.
//

import UIKit

class FloatingManager {
    static let shared = FloatingManager()
    
    private var downloadViews: [FloatingDownloadView] = []
    private weak var parentView: UIView?
    
    private init() {}
    
    func setup(in view: UIView) {
        parentView = view
    }
    
    func addDownload(title: String, imageURL: String) -> FloatingDownloadView {
        guard let parentView = parentView else {
            fatalError("Parent view is not set.")
        }
        
        let downloadView = FloatingDownloadView(title: title, imageURL: imageURL)
        downloadViews.append(downloadView)
        parentView.addSubview(downloadView)
        updateLayout()
        return downloadView
    }
    
    func removeDownload(_ downloadView: FloatingDownloadView) {
        if let index = downloadViews.firstIndex(of: downloadView) {
            downloadViews.remove(at: index)
            downloadView.removeFromSuperview()
            updateLayout()
        }
    }
    
    private func updateLayout() {
        guard let parentView = parentView else { return }
        
        for (index, view) in downloadViews.enumerated() {
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                view.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -CGFloat(20 + index * 90)),
                view.widthAnchor.constraint(equalToConstant: 250),
                view.heightAnchor.constraint(equalToConstant: 80)
            ])
        }
    }
}

