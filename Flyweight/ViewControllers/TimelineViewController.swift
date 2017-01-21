// Flyweight - iOS client for GNU social
// Copyright 2017 Thomas Karpiniec
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import CoreData

class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var loadMoreView: UIView!
    @IBOutlet weak var loadMoreButton: UIButton!
    
    
    var session: Session?
    var timeline: GSTimelineMO?
    var notices: [NoticeInGSTimelineMO] = []
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    @IBAction func refreshTapped(_ sender: AnyObject) {
        let _ = session?.gsTimelineManager.refreshPublicTimeline(lastNotice: self.notices.first)
            .then { (result: RefreshResult) -> Void in
                NSLog("Timeline should update now inserting \(result.noticesToInsert.count) with clear first \(result.clearListFirst)")
                if result.clearListFirst {
                    self.notices = []
                    self.tableView.reloadData()
                }
                self.notices = result.noticesToInsert + self.notices
                var indexPaths: [IndexPath] = []
                for i in 0..<result.noticesToInsert.count {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                let rectOfFirst = self.tableView.rectForRow(at: IndexPath(row: 0, section: 0))
                var offset = self.tableView.contentOffset
                self.tableView.insertRows(at: indexPaths, with: .none)
                let newRectOfFirst = self.tableView.rectForRow(at: IndexPath(row: result.noticesToInsert.count, section: 0))
                let heightDiff = newRectOfFirst.origin.y - rectOfFirst.origin.y
                offset.y += heightDiff
                self.tableView.setContentOffset(offset, animated: false)
        }
    }
    
    override func viewDidLoad() {
        
        tableView.register(UINib.init(nibName: "NoticeCell", bundle: Bundle.main), forCellReuseIdentifier: "notice")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120.0
        tableView.separatorStyle = .none
        
        session = SessionManager.activeSession
        timeline = session?.gsTimelineManager.getPublicTimeline(instance: nil)
        if let timeline = timeline {
            let initialNotices = session?.gsTimelineManager.getNoticesForTimeline(timeline: timeline)
            notices = initialNotices?.noticesToInsert ?? []
            tableView.tableFooterView = (initialNotices?.loadMorePossible ?? true) ? loadMoreView : nil
            NSLog("Loaded timeline and found \(notices.count) notices")
            self.tableView.reloadData()
        }
    }
    
    @IBAction func loadMoreTapped(_ sender: Any) {
        NSLog("Load more tapped")
        let _ = session?.gsTimelineManager.loadMorePublicTimeline(maxNotice: self.notices.last)
            .then { (result: LoadMoreResult) -> Void in
                NSLog("Timeline should update now append \(result.noticesToInsert.count) with load more possible \(result.loadMorePossible)")

                // Fairly simple when we're appending to the end
                self.notices = self.notices + result.noticesToInsert
                self.tableView.reloadData()
                
                self.tableView.tableFooterView = result.loadMorePossible ? self.loadMoreView : nil
        }

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notices.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "notice") as! NoticeCell?) ?? NoticeCell()
        cell.profileImage.url = nil
        cell.noticeText.text = ""
        cell.nickText.text = ""
        cell.fullNameText.text = ""
        cell.time.text = ""
        cell.likeCount.text = ""
        cell.repeatCount.text = ""
        
        let row = indexPath.row
        if row > notices.count {
            return cell
        }
        
        if let notice = notices[row].notice {
            cell.noticeText.text = notice.htmlContent
            cell.nickText.text = notice.user?.screenName
            cell.fullNameText.text = notice.user?.name
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            if let published = notice.published {
                cell.time.text = formatter.string(from: published as Date)
            }
            cell.profileImage.session = session
            if let avatars = notice.user?.avatars {
                var biggest: UserAvatarMO?
                for obj in avatars {
                    if let av = obj as? UserAvatarMO {
                        if av.width > biggest?.width ?? 0 {
                            biggest = av
                        }
                    }
                }
                cell.profileImage.url = biggest?.url
                session?.binaryManager.downloadImageIfNecessary(biggest?.url)
            } else {
                cell.profileImage.url = nil
            }
            cell.likeCount.isHidden = notice.faveNum < 0
            cell.repeatCount.isHidden = notice.repeatNum < 0
            cell.likeCount.text = "\(notice.faveNum)"
            cell.repeatCount.text = "\(notice.repeatNum)"
        }
        return cell
    }
    
    func moreToLoad() {
        self.loadMoreButton.titleLabel?.text = "Load more..."
    }
    
    func noMoreNotices() {
        self.loadMoreButton.titleLabel?.text = "No more notices"
    }
    
    func noNotices() {
        self.loadMoreButton.titleLabel?.text = "No notices"
    }
}
