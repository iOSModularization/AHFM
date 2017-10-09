//
//  AHFMSubscriptionCell.swift
//  Pods
//
//  Created by Andy Tong on 8/27/17.
//
//

import UIKit
import SDWebImage

private let SubscribeBtnWidth: CGFloat = 30.0
private let SubscribeBtnTrailingSpaceShown: CGFloat = 16.0
private let SubscribeBtnTrailingSpaceHidden: CGFloat = 2.0

protocol AHFMSubscriptionCellDelegate: class {
    func subscriptionCellDidTappSubscribeBtn(_ cell: UITableViewCell)
}

class AHFMSubscriptionCell: UITableViewCell {
    weak var delegate: AHFMSubscriptionCellDelegate?
    
    var editControlLeftPadding: CGFloat = 8.0
    weak var editControlBtn: UIButton!
    var editControlSize: CGSize = CGSize(width: 20.0, height: 20.0)
    
    
    @IBOutlet weak var subscribeBtnTrailingSpace: NSLayoutConstraint!
    var showSubscribeBtn = false {
        didSet {
            if showSubscribeBtn {
                subscribeBtnWidth.constant = SubscribeBtnWidth
            }else{
                subscribeBtnWidth.constant = 0.0
            }
        }
    }

    private var isDeleting = false
    
    @IBOutlet weak var subscribeBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var showCoverImg: UIImageView!
    @IBOutlet weak var subscribeBtn: UIButton!

    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var showTitle: UILabel!
    
    var isEditingMode = false

 var show: Show? {
        didSet {
            if let show = show {
                showTitle.text = show.title
                episodeTitle.text = show.title
                let url = URL(string: show.thumbCover ?? "")
                showCoverImg.sd_setImage(with: url, completed: { (image, error, _, _) in
                    guard self.show == show else {
                        return
                    }
                    guard error == nil else {
                        return
                    }
                    
                    if let image = image {
                        self.showCoverImg.image = image
                    }
                    
                })
            }
        }
    }
    
    @IBAction func subscribeBtnTapped(_ sender: UIButton) {
        delegate?.subscriptionCellDidTappSubscribeBtn(self)
    }
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
        
        subscribeBtnWidth.constant = 0.0
        
        subscribeBtn.layer.masksToBounds = true
        subscribeBtn.layer.cornerRadius = 5
        subscribeBtn.layer.borderColor = UIColor.lightGray.cgColor
        subscribeBtn.layer.borderWidth = 1.0

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        subscribeBtnWidth.constant = 0.0

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










