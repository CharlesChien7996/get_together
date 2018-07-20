//
//  eventOrganiserCell.swift
//  Get together
//
//  Created by 簡士荃 on 2018/7/20.
//  Copyright © 2018年 Charles. All rights reserved.
//

import UIKit

class eventOrganiserCell: UITableViewCell {
    @IBOutlet weak var organiserIcon: UIImageView!
    @IBOutlet weak var organiserProfileImage: UIImageView!
    
    @IBOutlet weak var organiserName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
