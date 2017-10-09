//
//  AHFMHisotryCell.swift
//  Pods
//
//  Created by Andy Tong on 8/27/17.
//
//

import UIKit

import SDWebImage
import UIImageExtension

class AHFMHisotryCell: UITableViewCell {
    @IBOutlet weak var percentPlayed: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverImg: UIImageView!
    var isEditingMode = false
    var episode: Episode? {
        didSet {
            if let episode = episode {
                var percent: Int = 0
                if let lastPlayedTime = episode.lastPlayedTime, let duration = episode.duration {
                    percent = Int((lastPlayedTime / duration) * 100)
                }
                
                if percent > 0 {
                    percentPlayed.textColor = UIColor.blue
                    percentPlayed.text = "\(percent)% played"
                }else{
                    percentPlayed.textColor = UIColor.red
                    percentPlayed.text = "Not started"
                }
                
                detailLabel.text = episode.title
                titleLabel.text = episode.showTitle
                
                let url = URL(string: episode.showThumbCover ?? "")
                coverImg.sd_setImage(with: url, completed: { (image, error, _, _) in
                    guard error == nil else {
                        return
                    }
                    guard let thisEp = self.episode else {
                        return
                    }
                    guard thisEp.id == episode.id else {
                        return
                    }
                    
                    guard let image = image else {
                        return
                    }
                    
                    self.coverImg.image = image
                    
                })
            }
        }
    }
    var editControlLeftPadding: CGFloat = 8.0
    weak var editControlBtn: UIButton!
    var editControlSize: CGSize = CGSize(width: 20.0, height: 20.0)
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        let editControlBtn = UIButton(type: .custom)
        editControlBtn.isUserInteractionEnabled = false
        editControlBtn.frame.size = editControlSize
        editControlBtn.frame.origin = CGPoint(x: -editControlSize.width - editControlLeftPadding, y: 0)
        let normalImg = UIImage(name: "editing-mark-normal", user: self)
        editControlBtn.setImage(normalImg, for: .normal)
        let selectedImg = UIImage(name: "editing-mark-selected", user: self)
        editControlBtn.setImage(selectedImg, for: .selected)
        self.addSubview(editControlBtn)
        self.editControlBtn = editControlBtn
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // cell will be checked at layoutSubviews()
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.isEditingMode = editing
        UIView.animate(withDuration: 0.3) {
            self.checkEditingMode()
        }
    }
    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        editControlBtn.isSelected = selected
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        checkEditingMode()
    }
    
    func checkEditingMode() {
        editControlBtn.frame.origin.y = self.bounds.height * 0.5 - editControlSize.height * 0.5
        let offset: CGFloat = self.editControlSize.width + self.editControlLeftPadding * 2
        self.contentView.frame.origin.x = offset
        self.editControlBtn.frame.origin.x = self.editControlLeftPadding
        
        if self.isEditingMode {
            self.contentView.frame.origin.x = offset
            self.editControlBtn.frame.origin.x = self.editControlLeftPadding
        }else{
            self.contentView.frame.origin.x = 0.0
            self.editControlBtn.frame.origin.x = -offset
        }
    }
    
}
