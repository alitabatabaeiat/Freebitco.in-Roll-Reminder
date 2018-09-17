//
//  AccountTableViewCell.swift
//  Freebitco.in Roll Reminder
//
//  Created by Ali Tabatabaei on 9/13/18.
//  Copyright © 2018 Ali Tabatabaei. All rights reserved.
//

import UIKit

class AccountTableViewCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var rewardPointsLabel: UILabel!
    @IBOutlet weak var rollButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setAccount(_ account: Account) {
        emailLabel.text = account.email
        nameLabel.text = account.name
        balanceLabel.text = "Approximate Balance: \(account.balance)"
        rewardPointsLabel.text = "Approximate Reward Points: \(account.reward_points)"
    }
    
    func setTag(_ tag: Int) {
        rollButton.tag = tag
    }
    
    

}
