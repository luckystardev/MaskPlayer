//
//  ViewController.swift
//  MaskPlayer
//
//  Created by Alex on 5/24/20.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit
import DKImagePickerController
import Photos
import AVKit

class myFolder {
    var title: String
    var assets: [DKAsset]?

    init(title:String, assets: [DKAsset]?){
        self.title = title
        self.assets = assets
    }
    
    func updateTitle(_ title: String) {
        self.title = title
    }
    
    func updateAssets(_ assets: [DKAsset]?) {
        self.assets = assets
    }
}

enum PICK_STATUS: Int {
    case new     = 100
    case add     = 200
}

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DKImageAssetExporterObserver {
    
    var pickerController: DKImagePickerController!
    @IBOutlet var previewView: UICollectionView?
    @IBOutlet weak var folderCV: UICollectionView?
    
    var exportManually = false
    var assets: [DKAsset]?
    var folders:[myFolder]? = [myFolder]()
    var currentFolderIndex: Int! = 0
    var currentTitle: String = ""
    var pickStatus = PICK_STATUS.new
    
    deinit {
        DKImagePickerControllerResource.customLocalizationBlock = nil
        DKImagePickerControllerResource.customImageBlock = nil
        
        DKImageExtensionController.unregisterExtension(for: .camera)
        DKImageExtensionController.unregisterExtension(for: .inlineCamera)
        
        DKImageAssetExporter.sharedInstance.remove(observer: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        pickerController = DKImagePickerController()
        pickerController.assetType = .allVideos
    }

    @IBAction func pickVideoAction(_ sender: Any) {
        showImagePicker()
    }
    
    @IBAction func pickVideoWithFolderAction(_ sender: Any) {
        let ac = UIAlertController(title: "Enter Folder name", message: nil, preferredStyle: .alert)
        ac.addTextField() { newTextField in
        }
        
        let createAction = UIAlertAction(title: "CREATE", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            // do something interesting with "answer" here
            if answer.text != "" {
                self.currentTitle = answer.text!
                self.assets?.removeAll()
                self.assets = [DKAsset]()
                self.pickStatus = PICK_STATUS.new
                self.currentFolderIndex = self.folders?.count
                self.showImagePicker()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [] _ in
            // do something interesting with "answer" here
        }
        
        ac.addAction(createAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    func showImagePicker() {
        if self.exportManually {
            DKImageAssetExporter.sharedInstance.add(observer: self)
        }
        
        if let assets = self.assets {
            pickerController.select(assets: assets)
        }
        
        pickerController.exportStatusChanged = { status in
            switch status {
            case .exporting:
                print("exporting")
            case .none:
                print("none")
            }
        }
        
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            self.updateAssets(assets: assets)
        }
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            pickerController.modalPresentationStyle = .formSheet
        }
        
        if pickerController.UIDelegate == nil {
            pickerController.UIDelegate = AssetClickHandler()
        }
        
        if pickerController.inline {
            self.showInlinePicker()
        } else {
            self.present(pickerController, animated: true) {}
        }
    }
    
    func updateAssets(assets: [DKAsset]) {
        print("didSelectAssets")
        
        self.assets = assets
        if self.pickStatus == PICK_STATUS.new {
            let newfolder = myFolder(title: self.currentTitle, assets: assets)
            self.folders?.append(newfolder)
            self.folderCV?.reloadData()
        } else {
            let folder = self.folders![currentFolderIndex]
            folder.updateAssets(assets)
        }
        
        self.previewView?.reloadData()
        
        if pickerController.exportsWhenCompleted {
            for asset in assets {
                if let error = asset.error {
                    print("exporterDidEndExporting with error:\(error.localizedDescription)")
                } else {
                    print("exporterDidEndExporting:\(asset.localTemporaryPath!)")
                }
            }
        }
        
        if self.exportManually {
            DKImageAssetExporter.sharedInstance.exportAssetsAsynchronously(assets: assets, completion: nil)
        }
    }
    
    func playVideo(_ asset: AVAsset) {
        let avPlayerItem = AVPlayerItem(asset: asset)
        
        let avPlayer = AVPlayer(playerItem: avPlayerItem)
        let player = AVPlayerViewController()
        
//        let maskview:UIImageView = UIImageView(image: UIImage(named: "mask"))
//        maskview.contentMode = .scaleToFill
//        maskview.frame = self.view.frame
//        player.contentOverlayView?.addSubview(maskview)
        player.player = avPlayer
        avPlayer.play()
        
        self.present(player, animated: true, completion: nil)
    }
    
    @objc func addButtonSelected(sender: UIButton){
        currentFolderIndex = sender.tag
        let folder = self.folders![currentFolderIndex]
        self.assets = folder.assets
        self.pickStatus = PICK_STATUS.add
        self.showImagePicker()
    }
    
    @objc func editButtonSelected(sender: UIButton){
        let folder = self.folders![sender.tag]
        let oldTitle = folder.title
        let ac = UIAlertController(title: "Edit Folder name", message: nil, preferredStyle: .alert)
        ac.addTextField() { newTextField in
            newTextField.text = oldTitle
        }
        
        let createAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            // do something interesting with "answer" here
            if answer.text != "" {
                folder.updateTitle(answer.text!)
                self.folders![sender.tag] = folder
                self.folderCV?.reloadData()
            }
        }
        
        ac.addAction(createAction)
        present(ac, animated: true)
    }
    
    @objc func deleteButtonSelected(sender: UIButton){
        self.folders?.remove(at: sender.tag)
        self.folderCV?.reloadData()
        self.previewView?.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource, UICollectionViewDelegate
       
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if collectionView == self.folderCV {
        return self.folders?.count ?? 0
    }
       return self.assets?.count ?? 0
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.folderCV {
            let folder = self.folders![indexPath.item]
            let title = folder.title
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FolderCell", for: indexPath) as! FolderCell
            cell.titleLbl.text = title
            
            cell.addBtn.addTarget(self, action: #selector(addButtonSelected), for: .touchUpInside)
            cell.editBtn.addTarget(self, action: #selector(editButtonSelected), for: .touchUpInside)
            cell.deleteBtn.addTarget(self, action: #selector(deleteButtonSelected), for: .touchUpInside)
            cell.addBtn.tag = indexPath.row
            cell.editBtn.tag = indexPath.row
            cell.deleteBtn.tag = indexPath.row
            
            cell.layer.borderWidth = 2
            if indexPath.item == currentFolderIndex {
                cell.layer.borderColor = UIColor.red.cgColor
            } else {
                cell.layer.borderColor = UIColor.clear.cgColor
            }
            
            return cell
        } else {
            let asset = self.assets![indexPath.row]
            var cell: UICollectionViewCell?
            var imageView: UIImageView?
            var maskView: UIView?
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellVideo", for: indexPath)
            imageView = cell?.contentView.viewWithTag(1) as? UIImageView
            maskView = cell?.contentView.viewWithTag(2)
            
            if let cell = cell, let imageView = imageView {
                let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
                let tag = indexPath.row + 1
                cell.tag = tag
                asset.fetchImage(with: layout.itemSize.toPixel(), completeBlock: { image, info in
                    if cell.tag == tag {
                        imageView.image = image
                    }
                })
            }
            
            maskView?.isHidden = !self.exportManually
            
            return cell!
        }
       
   }
   
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//       let asset = self.assets![indexPath.row]
//       asset.fetchAVAsset { (avAsset, info) in
//           DispatchQueue.main.async(execute: { () in
//               self.playVideo(avAsset!)
//           })
//       }
    
        if collectionView == folderCV {
            print("folderCV selected")
            currentFolderIndex = indexPath.item
            let folder = self.folders![indexPath.item]
            self.assets = folder.assets
            self.folderCV?.reloadData()
            self.previewView?.reloadData()
        } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "PlayerVC") as! PlayerVC
                vc.currentIndex = indexPath.row
                vc.assets = self.assets!
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
        }
        
   }
    
    // MARK: - Inline Mode
    
    func showInlinePicker() {
        let pickerView = self.pickerController.view!
        pickerView.frame = CGRect(x: 0, y: 170, width: self.view.bounds.width, height: 200)
        self.view.addSubview(pickerView)
        
        let doneButton = UIButton(type: .custom)
        doneButton.setTitleColor(UIColor.blue, for: .normal)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        doneButton.frame = CGRect(x: 0, y: pickerView.frame.maxY, width: pickerView.bounds.width / 2, height: 50)
        self.view.addSubview(doneButton)
        self.pickerController.selectedChanged = { [unowned self] in
            print("selectedChanged")
            self.updateDoneButtonTitle(doneButton)
        }
        self.updateDoneButtonTitle(doneButton)
        
        let albumButton = UIButton(type: .custom)
        albumButton.setTitleColor(UIColor.blue, for: .normal)
        albumButton.setTitle("Album", for: .normal)
        albumButton.addTarget(self, action: #selector(showAlbum), for: .touchUpInside)
        albumButton.frame = CGRect(x: doneButton.frame.maxX, y: doneButton.frame.minY, width: doneButton.bounds.width, height: doneButton.bounds.height)
        self.view.addSubview(albumButton)
    }
    
    func updateDoneButtonTitle(_ doneButton: UIButton) {
        doneButton.setTitle("Done(\(self.pickerController.selectedAssets.count))", for: .normal)
    }
    
    @objc func done() {
        self.updateAssets(assets: self.pickerController.selectedAssets)
    }
    
    @objc func showAlbum() {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = self.pickerController.maxSelectableCount
        pickerController.select(assets: self.pickerController.selectedAssets)
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            self.updateAssets(assets: assets)
            self.pickerController.setSelectedAssets(assets: assets)
        }
        
        self.present(pickerController, animated: true, completion: nil)
    }
    
    // MARK: - DKImageAssetExporterObserver
    
    func exporterWillBeginExporting(exporter: DKImageAssetExporter, asset: DKAsset) {
        if let index = self.assets?.firstIndex(of: asset) {
            if let cell = self.previewView?.cellForItem(at: IndexPath(item: index, section: 0)) {
                if let maskView = cell.contentView.viewWithTag(2) {
                    maskView.frame = CGRect(x: maskView.frame.minX,
                                            y: maskView.frame.minY,
                                            width: maskView.frame.width,
                                            height: maskView.frame.width)
                }
            }
        }
        
        print("exporterWillBeginExporting")
    }
    
    func exporterDidUpdateProgress(exporter: DKImageAssetExporter, asset: DKAsset) {
        if let index = self.assets?.firstIndex(of: asset) {
            if let cell = self.previewView?.cellForItem(at: IndexPath(item: index, section: 0)) {
                if let maskView = cell.contentView.viewWithTag(2) {
                    maskView.frame = CGRect(x: maskView.frame.minX,
                                            y: maskView.frame.minY,
                                            width: maskView.frame.width,
                                            height: maskView.frame.width * (1 - CGFloat(asset.progress)))
                }
            }
            
            print("exporterDidUpdateProgress with \(asset.progress)")
        }
    }
    
    func exporterDidEndExporting(exporter: DKImageAssetExporter, asset: DKAsset) {
        if let index = self.assets?.firstIndex(of: asset) {
            if let cell = self.previewView?.cellForItem(at: IndexPath(item: index, section: 0)) {
                if let maskView = cell.contentView.viewWithTag(2) {
                    maskView.isHidden = true
                }
            }
            
            if let error = asset.error {
                print("exporterDidEndExporting with error:\(error.localizedDescription)")
            } else {
                print("exporterDidEndExporting:\(asset.localTemporaryPath!)")
            }
        }
    }
}

// MARK: - DKImagePickerControllerBaseUIDelegate

class AssetClickHandler: DKImagePickerControllerBaseUIDelegate {
    override func imagePickerController(_ imagePickerController: DKImagePickerController, didSelectAssets: [DKAsset]) {
        //tap to select asset
        //use this place for asset selection customisation
        print("didClickAsset for selection")
    }
    
    override func imagePickerController(_ imagePickerController: DKImagePickerController, didDeselectAssets: [DKAsset]) {
        //tap to deselect asset
        //use this place for asset deselection customisation
        print("didClickAsset for deselection")
    }
}
