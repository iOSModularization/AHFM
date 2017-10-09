//
//  AHFMCategoryCollectonVC.swift
//  Pods
//
//  Created by Andy Tong on 7/31/17.
//
//

import UIKit
import BundleExtension

private let AHFMCategoryCollectonCellID = "AHFMCategoryCollectonCellID"

protocol AHFMCategoryCollectonVCDelegate:class {
    func categoryCollectonVC(_ vc: AHFMCategoryCollectonVC, didSelectShow showId: Int)
}

class AHFMCategoryCollectonVC: UICollectionViewController {
    weak var delegate: AHFMCategoryCollectonVCDelegate?
    
    var shows: [Show]? {
        didSet {
            if let _ = shows {
                collectionView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.backgroundColor = UIColor.white
        let currentBundle = Bundle.currentBundle(self)
        let nib = UINib(nibName: "\(AHFMCategoryCollectionCell.self)", bundle: currentBundle)
        collectionView?.register(nib, forCellWithReuseIdentifier: AHFMCategoryCollectonCellID)
        
        collectionView?.contentInset.left = Padding
        collectionView?.contentInset.right = Padding
        collectionView?.showsHorizontalScrollIndicator = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return shows?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AHFMCategoryCollectonCellID, for: indexPath) as! AHFMCategoryCollectionCell
    
        cell.show = shows?[indexPath.item]
    
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let shows = self.shows else {
            return
        }
        let show = shows[indexPath.row]
        self.delegate?.categoryCollectonVC(self, didSelectShow: show.id)
        
    }
    
}







