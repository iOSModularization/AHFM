//
//  AHFMShowHeader.swift
//  Pods
//
//  Created by Andy Tong on 7/26/17.
//
//

import UIKit

import SDWebImage
import AHNibLoadable
import AHStackButton
import UIImageExtension

public protocol AHFMShowHeaderDelegate: class {
    func showHeaderShareBtnTapped(_ header: AHFMShowHeader)
    func showHeaderDownloadBtnTapped(_ header: AHFMShowHeader)
    /// Invoke completion when finish like process.
    func showHeaderLikeBtnTapped(_ header: AHFMShowHeader)
    func showHeaderIntroTapped(_ header: AHFMShowHeader)
}


public class AHFMShowHeader: UIView, AHNibLoadable {
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var showImgBtn: UIButton! {
        didSet {
            showImgBtn.imageView?.contentMode = .scaleAspectFit
        }
    }
    @IBOutlet weak var scoreBtn: AHStackButton! {
        didSet {
            let imgN = UIImage(name: "0-star", user: self)
            scoreBtn.setImage(imgN, for: .normal)
            scoreBtn.imageView?.contentMode = .scaleAspectFit
            scoreBtn.isTitleOn = .left
        }
    }

    @IBOutlet weak var showDetailLabel: UILabel!
    @IBOutlet weak var toolBar: UIView!
    @IBOutlet weak var likeBtn: AHStackButton!{
        didSet {
            let imgN = UIImage(name: "like-normal", user: self)
            let imgS = UIImage(name: "like-selected", user: self)
            likeBtn.setImage(imgN, for: .normal)
            likeBtn.setImage(imgS, for: .selected)
            likeBtn.isTitleOn = .bottom
        }
    }
    @IBOutlet weak var downloadBtn: AHStackButton! {
        didSet {
            let imgN = UIImage(name: "download-1-icon", user: self)
            downloadBtn.setImage(imgN, for: .normal)
            downloadBtn.isTitleOn = .bottom
        }
    }
    @IBOutlet weak var shareBtn: AHStackButton! {
        didSet{
            let imgN = UIImage(name: "share", user: self)
            shareBtn.setImage(imgN, for: .normal)
            shareBtn.isTitleOn = .bottom
        }
    }
    public weak var delegate: AHFMShowHeaderDelegate?
    
    var isSubscribed = false {
        didSet {
            self.likeBtn.isSelected = isSubscribed
        }
    }
    
    var show: Show? {
        didSet {
            if let show = show {
                let bgImgURL = URL(string: show.fullCover)
                bgImageView.sd_setImage(with: bgImgURL)
                
                let thumbImgURL = URL(string: show.thumbCover)
                showImgBtn.sd_setImage(with: thumbImgURL, for: .normal)
                
                showDetailLabel.text = show.detail
                
                
                
            }
        }
    }
    
    
    @IBAction func shareBtnTapped(_ sender: UIButton) {
        delegate?.showHeaderShareBtnTapped(self)
    }
    
    @IBAction func downloadBtnTapped(_ sender: Any) {
        delegate?.showHeaderDownloadBtnTapped(self)
    }
    @IBAction func likeBtnTapped(_ sender: UIButton) {
        delegate?.showHeaderLikeBtnTapped(self)
    }
    @IBAction func headerTapped(_ sender: UITapGestureRecognizer) {
        delegate?.showHeaderIntroTapped(self)
    }
}







