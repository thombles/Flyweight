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
    
    override func awakeFromNib() {
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
}
