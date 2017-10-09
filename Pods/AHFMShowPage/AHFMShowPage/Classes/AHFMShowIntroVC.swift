//
//  AHFMShowIntroVC.swift
//  Pods
//
//  Created by Andy Tong on 7/27/17.
//
//

import UIKit
import SDWebImage

class AHFMShowIntroVC: UIViewController {
    @IBOutlet var showCover: UIImageView!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var detailBtn: UIButton!
    
    var dismissBlock: (()->Void)?
    
    var show: Show?
    
    ///########## VC Class Related
    public init() { // programatic initializer
        let bundle = Bundle(for: type(of: self))
        super.init(nibName: "\(type(of: self))", bundle: bundle)
    }
    
    required public init?(coder aDecoder: NSCoder) { // storyboard initializer
        /*
         if override this method like:
         let bundle = Bundle(for: AHFMPlayerView.self)
         super.init(nibName: "AHFMPlayerView", bundle: bundle)
         then the navigation bar is not shown.
         not a good override
         */
        super.init(coder: aDecoder)
        let bundle = Bundle(for: type(of: self))
        let xibView = bundle.loadNibNamed("\(type(of: self))", owner: self, options: nil)!.first as! UIView
        self.view = xibView
    }
    
    ///########## End VC Class Related
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let show = show {
            let coverURL = URL(string: show.fullCover)
            showCover.sd_setImage(with: coverURL)
            
            titleLabel.text = show.title
            detailBtn.titleLabel?.numberOfLines = 0
            detailBtn.setTitle(show.detail, for: .normal)
        }
        
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissBlock?()
        dismiss(animated: false, completion: nil)
    }

}
