//
//  AHLayout.swift
//  Pods
//
//  Created by Andy Tong on 9/4/17.
//
//

import UIKit


public class AHDraggableLayout: UICollectionViewFlowLayout {
    var longPress: UILongPressGestureRecognizer!
    var originalIndexPath: IndexPath?
    var draggingIndexPath: IndexPath?
    var draggingView: UIView?
    var dragOffset = CGPoint.zero
    
    
    public override func prepare() {
        super.prepare()
        
        installGestureRecognizer()
    }
    
    func applyDraggingAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        attributes.alpha = 0
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        attributes?.forEach { a in
            if a.indexPath == draggingIndexPath {
                if a.representedElementCategory == .cell {
                    self.applyDraggingAttributes(a)
                }
            }
        }
        return attributes
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        if let attributes = attributes, indexPath == draggingIndexPath {
            if attributes.representedElementCategory == .cell {
                applyDraggingAttributes(attributes)
            }
        }
        return attributes
    }
    func installGestureRecognizer() {
        if longPress == nil {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(AHDraggableLayout.handleLongPress(_:)))
            longPress.minimumPressDuration = 0.2
            collectionView?.addGestureRecognizer(longPress)
        }
    }
    
    func handleLongPress(_ longPress: UILongPressGestureRecognizer) {
        let location = longPress.location(in: collectionView!)
        switch longPress.state {
        case .began: startDragAtLocation(location)
        case .changed: updateDragAtLocation(location)
        case .ended: endDragAtLocation(location)
        default:
            break
        }
    }
    
    func startDragAtLocation(_ location: CGPoint) {
        guard let cv = collectionView else { return }
        guard let indexPath = cv.indexPathForItem(at: location) else { return }
        guard cv.dataSource?.collectionView?(cv, canMoveItemAt: indexPath) == true else { return }
        guard let cell = cv.cellForItem(at: indexPath) else { return }
        
        originalIndexPath = indexPath
        draggingIndexPath = indexPath
        draggingView = cell.snapshotView(afterScreenUpdates: true)
        draggingView!.frame = cell.frame
        cv.addSubview(draggingView!)
        
        dragOffset = CGPoint(x: draggingView!.center.x - location.x, y: draggingView!.center.y - location.y)
        
        draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
        draggingView?.layer.shadowColor = UIColor.black.cgColor
        draggingView?.layer.shadowOpacity = 0.5
        draggingView?.layer.shadowRadius = 2
        draggingView?.layer.shadowOffset = CGSize(width: 1, height: 2)
        
        invalidateLayout()
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            self.draggingView?.alpha = 0.95
            self.draggingView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
    }
    
    func updateDragAtLocation(_ location: CGPoint) {
        guard let view = draggingView else { return }
        guard let cv = collectionView else { return }
        
        view.center = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        
        if let newIndexPath = cv.indexPathForItem(at: location) {
            cv.moveItem(at: draggingIndexPath!, to: newIndexPath)
            draggingIndexPath = newIndexPath
        }
    }
    
    func endDragAtLocation(_ location: CGPoint) {
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        guard let cv = collectionView else { return }
        guard let datasource = cv.dataSource else { return }
        
        let targetCenter = datasource.collectionView(cv, cellForItemAt: indexPath).center
        
        let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
        shadowFade.fromValue = 0.8
        shadowFade.toValue = 0
        shadowFade.duration = 0.4
        dragView.layer.add(shadowFade, forKey: "shadowFade")
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            dragView.center = targetCenter
            dragView.transform = CGAffineTransform.identity
            
        }) { (completed) in
            
            if indexPath != self.originalIndexPath! {
                datasource.collectionView?(cv, moveItemAt: self.originalIndexPath!, to: indexPath)
            }
            
            dragView.removeFromSuperview()
            self.draggingIndexPath = nil
            self.draggingView = nil
            self.invalidateLayout()
        }
        
        
    }
}
