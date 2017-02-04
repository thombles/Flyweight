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

class NoticeCell: UITableViewCell {
    var session: Session?
    
    @IBOutlet weak var noticeText: ContentView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var profileImage: NetImage!
    @IBOutlet weak var nickText: UILabel!
    @IBOutlet weak var fullNameText: UILabel!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var repeatCount: UILabel!
    @IBOutlet weak var repeatImage: UIImageView!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var metaMessage: UILabel!
    @IBOutlet weak var metaHeight: NSLayoutConstraint!
    @IBOutlet weak var metaBottom: NSLayoutConstraint!
    
    override func awakeFromNib() {
        session = SessionManager.activeSession
        borderView.layer.masksToBounds = false
        borderView.layer.shadowColor = UIColor.black.cgColor
        borderView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        borderView.layer.shadowOpacity = 0.5
//        borderView.layer.borderColor = UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 0.6).CGColor
//        borderView.layer.borderWidth = 1.0
        
        // Set up tints on the right-side images and labels
        //likeCount.textColor = rightSideColour
        //repeatCount.textColor = rightSideColour
        likeImage.image = UIImage(named: "like")?.withRenderingMode(.alwaysTemplate)
        repeatImage.image = UIImage(named: "repeat")?.withRenderingMode(.alwaysTemplate)
        likeImage.tintColor = UIColor.darkGray
        repeatImage.tintColor = UIColor.darkGray
    }
    
    func hideRepeatedBy() {
        metaHeight.constant = 0
        metaBottom.constant = 0
        metaMessage.text = ""
    }
    
    // TODO make this tappable and show the profile page of the user who did the repeating
    
    func setRepeatedBy(name: String?) {
        let displayName = name ?? "a user with no name"
        metaHeight.constant = 16
        metaBottom.constant = 8
        metaMessage.text = "Repeated by \(displayName)"
    }
    
    var notice: NoticeMO? {
        didSet {
            // This is the one we will render by default, unless it's a repeat
            guard var notice = self.notice else {
                profileImage.url = nil
                noticeText.text = ""
                nickText.text = ""
                fullNameText.text = ""
                time.text = ""
                likeCount.text = ""
                repeatCount.text = ""
                hideRepeatedBy()
                return
            }
            
            if notice.isRepeat {
                if let repeatedNotice = notice.repeatedNotice {
                    // Take the user from the outer "did repeat" notice
                    setRepeatedBy(name: notice.user?.screenName)
                    // Everything else will have the appearance of being the original notice in the timeline
                    notice = repeatedNotice
                }
            }
            
            noticeText.htmlContent = notice.htmlContent
            nickText.text = notice.user?.name
            fullNameText.text = notice.user?.screenName
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            if let published = notice.published {
                time.text = formatter.string(from: published as Date)
            }
            if let avatars = notice.user?.avatars {
                var biggestReasonableSize: UserAvatarMO?
                for obj in avatars {
                    if let av = obj as? UserAvatarMO {
                        if av.width > biggestReasonableSize?.width ?? 0 && av.width <= 200 {
                            biggestReasonableSize = av
                        }
                    }
                }
                profileImage.url = biggestReasonableSize?.url
                session?.binaryManager.downloadImageIfNecessary(biggestReasonableSize?.url)
            } else {
                profileImage.url = nil
            }
            likeCount.isHidden = notice.faveNum < 0
            repeatCount.isHidden = notice.repeatNum < 0
            likeCount.text = "\(notice.faveNum)"
            repeatCount.text = "\(notice.repeatNum)"
        }
    }
}
