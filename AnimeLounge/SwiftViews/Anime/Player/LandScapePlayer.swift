//
//  LandScapePlayer.swift
//  AnimeLounge
//
//  Created by Francesco on 30/06/24.
//

import UIKit
import AVKit

class LandscapePlayer: AVPlayerViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
}
