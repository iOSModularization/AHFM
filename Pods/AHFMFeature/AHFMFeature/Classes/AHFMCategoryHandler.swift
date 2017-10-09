//
//  AHFMCategoryHandler.swift
//  Pods
//
//  Created by Andy Tong on 7/30/17.
//
//

import Foundation

class AHFMCategoryHandler: NSObject {
    weak var featureVC: AHFMFeatureVC?
    
    var categoryVCs = [AHFMCategoryCollectonVC]()
    func setup(_ featureVC: AHFMFeatureVC, cell: AHFMCategoryCell, showArray: [Show], section: Int, categoryName: String) {

        var vc: AHFMCategoryCollectonVC? = nil
        if section >= categoryVCs.count {
            // there's no VC for this section in categoryVCs
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = Padding
            layout.minimumInteritemSpacing = 0.0
            layout.itemSize = CollectionCellSize
            vc = AHFMCategoryCollectonVC(collectionViewLayout: layout)
            vc?.delegate = self
            categoryVCs.append(vc!)
            vc?.willMove(toParentViewController: featureVC)
            featureVC.addChildViewController(vc!)
            vc?.didMove(toParentViewController: featureVC)
        }else{
            vc = categoryVCs[section]
        }
        cell.categoryName.text = categoryName
        cell.targetView = vc?.view
        
        vc?.shows = showArray
    }
    
    
    
}

extension AHFMCategoryHandler: AHFMCategoryCollectonVCDelegate {
    func categoryCollectonVC(_ vc: AHFMCategoryCollectonVC, didSelectShow showId: Int) {
        guard let featureVC = self.featureVC else {
            return
        }
        featureVC.manager?.featureVC(featureVC, didTapCategoryWithShow: showId)
        
    }
}



