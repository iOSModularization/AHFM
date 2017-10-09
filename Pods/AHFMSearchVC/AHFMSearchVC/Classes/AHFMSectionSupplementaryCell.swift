//
//  AHFMSectionSupplementaryCell.swift
//  Pods
//
//  Created by Andy Tong on 9/6/17.
//
//

import UIKit

protocol AHFMSectionSupplementaryCellDelegate:class {
    func clearBtnTapped(_ cell: AHFMSectionSupplementaryCell)
}

class AHFMSectionSupplementaryCell: UICollectionReusableView {
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    var hideClearBtn = true {
        didSet{
            self.clearBtn.isHidden = self.hideClearBtn
        }
    }
    weak var delegate: AHFMSectionSupplementaryCellDelegate?

    @IBAction func clearBtnTapped(_ sender: UIButton) {
        delegate?.clearBtnTapped(self)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.clearBtn.isHidden = self.hideClearBtn
        
        self.clearBtn.layer.masksToBounds = true
        self.clearBtn.layer.cornerRadius = 5.0
        self.clearBtn.layer.borderColor = UIColor.red.cgColor
        self.clearBtn.layer.borderWidth = 1.0
    }
    
}
