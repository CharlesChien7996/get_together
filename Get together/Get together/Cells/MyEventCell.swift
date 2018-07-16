//
//  MyEventCell.swift
//  Get together
//
//  Created by 簡士荃 on 2018/7/4.
//  Copyright © 2018年 Charles. All rights reserved.
//

import UIKit

class MyEventCell: UITableViewCell {
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.eventTitle.textColor = UIColor.lightGray
        self.eventDate.textColor = UIColor.lightGray
        self.eventImageView.image = #imageLiteral(resourceName: "loading")
        self.eventTitle.text = "讀取中"
        self.eventDate.text = "讀取中"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
