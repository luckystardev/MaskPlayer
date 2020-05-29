//
//  PlayerVC.swift
//  MaskPlayer
//
//  Created by Alex on 5/29/20.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit
import AVKit
import DKImagePickerController

class PlayerVC: UIViewController {
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var backwardbtn: UIButton!
    @IBOutlet weak var forwardBtn: UIButton!
    @IBOutlet weak var maskBtn: UIButton!
    
    var assets: [DKAsset]?
    var currentIndex: Int!
    var maskview = UIImageView()
    var playerVC = AVPlayerViewController()
    var avPlayer = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerVC.view.frame = self.view.frame
        
        maskview = UIImageView(image: UIImage(named: "mask"))
        maskview.contentMode = .scaleToFill
        maskview.frame = self.view.frame
        playerVC.contentOverlayView?.addSubview(maskview)
        maskview.isHidden = true
        
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.didMove(toParent: self)
        
        controlView.layer.zPosition = 100
        controlView.layer.cornerRadius = 14
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        forwardBtn.isEnabled = false
        backwardbtn.isEnabled = false
        
        playVideo()
        
    }
    
    func playVideo() {
        if currentIndex < self.assets!.count - 1 {
            forwardBtn.isEnabled = true
        }
        if currentIndex != 0 && self.assets!.count > 1 {
            backwardbtn.isEnabled = true
        }
        
        let asset = self.assets![currentIndex]
        asset.fetchAVAsset { (avAsset, info) in
            DispatchQueue.main.async(execute: { () in
                let avPlayerItem = AVPlayerItem(asset: avAsset!)
                self.avPlayer = AVPlayer(playerItem: avPlayerItem)
                self.playerVC.player = self.avPlayer
                self.avPlayer.play()
                self.view.bringSubviewToFront(self.controlView)
            })
        }
    }
    
    @IBAction func backwardAction(_ sender: Any) {
        print("previous")
        currentIndex -= 1
        playVideo()
    }
    
    @IBAction func forwardAction(_ sender: Any) {
        print("next")
        playNextVideo()
    }
    
    func playNextVideo() {
        if currentIndex < self.assets!.count - 1 {
            currentIndex += 1
            playVideo()
        }
    }
    
    @IBAction func maskAction(_ sender: Any) {
        if maskview.isHidden {
            print("show")
            maskview.isHidden = false
        } else {
            print("hidden")
            maskview.isHidden = true
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
        playNextVideo()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
