//
//  AHFMRecomandDataSource.swift
//  Pods
//
//  Created by Andy Tong on 7/27/17.
//
//

import Foundation

fileprivate let ShowCellID = "AHFMRecommandCellID"

class AHFMShowRecomendDataSource: NSObject {
    var shows: [Show]? {
        didSet {
            if let tablView = tablView,let shows = shows, shows.count > 0 {
                tablView.reloadData()
            }
        }
    }
    weak var tablView: UITableView? {
        didSet {
            if let tableView = tablView {
                let nib = UINib(nibName: "\(AHFMShowRecommendCell.self)", bundle: Bundle.currentBundle(self))
                tableView.register(nib, forCellReuseIdentifier: ShowCellID)
            }
        }
    }
}

extension AHFMShowRecomendDataSource: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shows?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShowCellID, for: indexPath) as! AHFMShowRecommendCell
        let show = shows?[indexPath.row]
        cell.show = show
        return cell
    }
}
