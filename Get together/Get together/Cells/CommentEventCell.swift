//
//  CommentEventCell.swift
//  Get together
//
//  Created by 簡士荃 on 2018/8/9.
//  Copyright © 2018年 Charles. All rights reserved.
//

import UIKit

class CommentEventCell: UITableViewCell {
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
