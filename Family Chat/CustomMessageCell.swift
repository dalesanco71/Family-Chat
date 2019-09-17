//
//  CustomMessageCell.swift
//  Flash Chat
//
//  Created by Angela Yu on 30/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit

class CustomMessageCell: UITableViewCell {


    @IBOutlet var messageBackground: UIView!
    @IBOutlet var receiverAvatarImageView: UIImageView!
    @IBOutlet var messageBody: UILabel!
    @IBOutlet var senderAvatarImageView: UIImageView!
    @IBOutlet var senderUsername: UILabel!
    @IBOutlet var messageTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code goes here
        
        
    }


}
