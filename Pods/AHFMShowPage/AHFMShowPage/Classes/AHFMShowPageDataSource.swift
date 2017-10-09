//
//  AHFMShowPageCellHandler.swift
//  Pods
//
//  Created by Andy Tong on 7/27/17.
//
//

import Foundation
import BundleExtension

fileprivate let EpisodeCellID = "AHFMShowPageCellID"

class AHFMShowPageDataSource: NSObject {
    var episodes: [Episode]? {
        didSet{
            if let _ = episodes {
                self.tablView?.reloadData()
            }
        }
    }
    
    weak var tablView: UITableView? {
        didSet {
            if let tableView = tablView {
                let nib = UINib(nibName: "\(AHFMShowPageCell.self)", bundle: Bundle.currentBundle(self))
                tableView.register(nib, forCellReuseIdentifier: EpisodeCellID)
            }
        }
    }
}

extension AHFMShowPageDataSource: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.episodes?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EpisodeCellID, for: indexPath) as! AHFMShowPageCell
        let episode = self.episodes?[indexPath.row]
        cell.episode = episode
        cell.titleLabel.text = "\(indexPath.row) - \(cell.titleLabel.text!)"
        cell.delegate = self
        return cell
    }
}

extension AHFMShowPageDataSource:AHFMShowPageCellDelegate {
    func showPageCellDidTapDownloadBtn(_ cell: UITableViewCell) {
        guard let cell = cell as? AHFMShowPageCell else {
            return
        }
        cell.pause()
    }
}









