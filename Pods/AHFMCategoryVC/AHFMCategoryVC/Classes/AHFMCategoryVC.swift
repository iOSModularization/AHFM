//
//  AHFMCategoryVC.swift
//  Pods
//
//  Created by Andy Tong on 9/4/17.
//
//

import UIKit
import BundleExtension
import UIImageExtension
import AHDraggableLayout

private let reuseIdentifier = "Cell"
private let gray_ish: CGFloat = 245.0/255.0
private let BackgroundColor = UIColor(red: gray_ish, green: gray_ish, blue: gray_ish, alpha: 1.0)
private let CategoryUserDefaultKey = "CategoryUserDefaultKey"



@objc public protocol AHFMCategoryVCDelegate: class {
    func categoryVC(_ vc: UIViewController, didSelectCategory category: String)
    func viewWillAppear(_ vc: UIViewController)
    func viewWillDisappesar(_ vc: UIViewController)
}

public class AHFMCategoryVC: UICollectionViewController {
    public var manager: AHFMCategoryVCDelegate?
    
    init() {
        super.init(collectionViewLayout: AHDraggableLayout())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(collectionViewLayout: AHDraggableLayout())
    }
    
    var cateogryNames: [String]?
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView!.backgroundColor = BackgroundColor
        
        // Register cell classes
        let nib = UINib(nibName: "\(DummyCell.self)", bundle: Bundle(for: DummyCell.self))
        self.collectionView!.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.contentInset.bottom = 49.0
        self.collectionView?.isScrollEnabled = false
        let layout = AHDraggableLayout()
        self.collectionView!.setCollectionViewLayout(layout, animated: false)
        
        let cellWidth: CGFloat = (self.collectionView!.frame.width - 3.0) / 4
        
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0
        
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        manager?.viewWillAppear(self)
        
        if let cateogryNames = UserDefaults.standard.value(forKey: CategoryUserDefaultKey) as? [String] {
            self.cateogryNames = cateogryNames
            
        }else if let path = Bundle.resourceBundle(self)?.path(forResource: "CategoryMap.plist", ofType: nil){
            let pathUrl = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: pathUrl)
            let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
            
            if let iconMap = plist as? [String: String] {
                let cateogryNames = iconMap.flatMap({$0.0})
                self.cateogryNames = cateogryNames
                UserDefaults.standard.set(self.cateogryNames, forKey: CategoryUserDefaultKey)
            }
        }
        
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        manager?.viewWillDisappesar(self)
    }
    
    // MARK: UICollectionViewDataSource

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.cateogryNames?.count ?? 0
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! DummyCell

        let category = self.cateogryNames![indexPath.row]
        let iconName = "\(category)-icon"
        cell.categoryImageView.image = UIImage(name: iconName, user: self)
        cell.titleLabel.text = category
        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    public override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let name = self.cateogryNames?.remove(at: sourceIndexPath.row) {
            self.cateogryNames?.insert(name, at: destinationIndexPath.row)
            UserDefaults.standard.set(self.cateogryNames, forKey: CategoryUserDefaultKey)
        }
        
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let categoryName = self.cateogryNames![indexPath.row]
        self.manager?.categoryVC(self, didSelectCategory: categoryName)
    }
    
    
}
