//
//  AHFMDownloadedVC.swift
//  Pods
//
//  Created by Andy Tong on 8/8/17.
//
//

import UIKit
import AHDownloader
import UIImageExtension
import BundleExtension

private let AHFMDownloadedCellHeight: CGFloat = 100.0
private let AHFMDownloadedCellID = "AHFMDownloadedCellID"

protocol AHFMDownloadedVCDelegate: class {
    /// Call loadEpisodesForShow(_:) when data is ready
    func downloadedShowPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int)
    func downloadedVCShowPage(_ vc: UIViewController, didSelectShow showId: Int)
    func downloadedVCShowPage(_ vc: UIViewController, didSelectEpisode episodeId: Int, showId: Int)
    func downloadedVCShowPage(_ vc: UIViewController, didSelectDownloadMoreForShow showId: Int)
    
    /// Should hide or show bottomBar if there's any
    func downloadedShowPageVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool)
    
    /// Delete downloaded episodes for this showId
    func downloadedShowPageVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int)
    
    /// Call loadDownloadedShows(_:) when ready
    /// Load all shows with at least one downloaded episode
    func downloadedVCLoadDownloadedShows(_ vc: UIViewController)
    
    /// Delete all downloaded episodes for this showId
    func downloadedVC(_ vc: UIViewController, shouldDeleteShow showId: Int)
    
    /// You should unmark AHFMShow's hasNewDownload property for the showId
    func downloadedVC(_ vc: UIViewController, willEnterShowPageWithShowId showId: Int)
    
    /// Fetch the show that has an episode with that specific remote URL
    /// Call addHasNewDownloaded(_) when the data is ready
    func downloadedVC(_ vc: UIViewController, shouldFetchShowWithEpisodeRemoteURL url: String)
}

//MARK:- AHFMDownloadedVC
class AHFMDownloadedVC: UITableViewController {
    weak var delegate: AHFMDownloadedVCDelegate?
    
    fileprivate weak var showPageVC: AHFMDownloadedShowPageVC?
    
    fileprivate var shows: [Show]?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        let currentBundle = Bundle.currentBundle(self)
        let nib = UINib(nibName: "\(AHFMDownloadedCell.self)", bundle: currentBundle)
        tableView.register(nib, forCellReuseIdentifier: AHFMDownloadedCellID)

        tableView.separatorColor = UIColor.lightGray
        tableView.backgroundColor = UIColor.lightGray
        
        
        AHDownloader.addDelegate(self)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.delegate?.downloadedVCLoadDownloadedShows(self)
    }
    
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return shows?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AHFMDownloadedCellID, for: indexPath) as! AHFMDownloadedCell
        cell.show = shows?[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if var show = self.shows?[indexPath.row] {
            let vc = AHFMDownloadedShowPageVC()
            vc.delegate = self
            vc.show = show
            if self.navigationController != nil {
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                self.present(vc, animated: true, completion: nil)
            }
            self.showPageVC = vc
            if let cell = self.tableView.cellForRow(at: indexPath) as? AHFMDownloadedCell {
                show.hasNewDownload = false
                self.shows?[indexPath.row] = show
                cell.show = show
                self.delegate?.downloadedVC(self, willEnterShowPageWithShowId: show.id)
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AHFMDownloadedCellHeight
    }
    
}

//MARK:- Load Methods
extension AHFMDownloadedVC {
    func loadDownloadedShows(_ shows: [Show]?) {
        self.shows = shows
        self.tableView.reloadData()
    }
    
    func loadEpisodesForShow(_ showId: Int, eps: [Episode]) {
        showPageVC?.loadEpisodesForShow(showId, eps: eps)
    }
    
    
    /// the show could be already in self.shows and it had new downloaded episode coming in.
    func addHasNewDownloaded(_ show: Show?) {
        guard let show = show else {
            return
        }
        
        if let shows = self.shows {
            if let index = shows.index(of: show) {
                if shows.count == 1 {
                    // no need to do animation if there's only one show involved
                    self.shows?.remove(at: index)
                    self.shows?.append(show)
                    self.tableView.reloadData()
                    return
                }else{
                    // delete first, then add to top later
                    self.shows?.remove(at: index)
                    let indexPath = IndexPath(row: index, section: 0)
                    self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
                }
            }
        }else{
            self.shows = [Show]()
        }
        
        self.shows?.insert(show, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.top)
    }
}

//MARK:- AHFMDownloadedShowPageVCDelegate
extension AHFMDownloadedVC: AHFMDownloadedShowPageVCDelegate {
    /// Call loadEpisodesForShow(_:) when data is ready
    func downloadedShowPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int){
        self.delegate?.downloadedShowPageVC(vc, shouldLoadEpisodesForShow: showId)
    }
    func downloadedShowPageVC(_ vc: UIViewController, didSelectShow showId: Int){
        self.delegate?.downloadedVCShowPage(vc, didSelectShow: showId)
    }
    func downloadedShowPageVC(_ vc: UIViewController, didSelectEpisode episodeId: Int, showId: Int){
        self.delegate?.downloadedVCShowPage(vc, didSelectEpisode: episodeId, showId: showId)
    }
    func downloadedShowPageVC(_ vc: UIViewController, didSelectDownloadMoreForShow showId: Int){
        self.delegate?.downloadedVCShowPage(vc, didSelectDownloadMoreForShow: showId)
    }
    func downloadedShowPageVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool){
        self.delegate?.downloadedShowPageVC(vc, editingModeDidChange: isEditing)
    }
    func downloadedShowPageVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int) {
        self.delegate?.downloadedShowPageVC(vc, shouldDeleteEpisodes: episodeIDs, forShow: showId)
    }
}

//MARK:- AHFMDownloadedCellDelegate
extension AHFMDownloadedVC: AHFMDownloadedCellDelegate {
    func downloadedCell(_ cell: AHFMDownloadedCell, didTappedDelete showId: Int) {
        guard let shows = self.shows else {
            return
        }
        
        guard let show = shows.filter({ (show) -> Bool in
            return show.id == showId
        }).first else {
            return
        }

        guard let index = shows.index(of: show) else {
            return
        }
        
        self.shows?.remove(at: index)
        tableView.reloadData()
        
        self.delegate?.downloadedVC(self, shouldDeleteShow: showId)
    }
}

//MARK:- AHDownloaderDelegate
extension AHFMDownloadedVC: AHDownloaderDelegate {
    func downloaderDidFinishDownload(url:String, localFilePath: String) {
        self.delegate?.downloadedVC(self, shouldFetchShowWithEpisodeRemoteURL: url)
    }

}











