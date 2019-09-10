//
//  BulletinDetail_TableViewCell.swift
//  TestApp
//
//  Created by Fry an Egg on 6/1/19.
//  Copyright © 2019 Fry an Egg. All rights reserved.
//

import UIKit

class BulletinDetail_TableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel:UILabel!
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var bulletinImageView:UIImageView!
    @IBOutlet weak var descriptionField:UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
