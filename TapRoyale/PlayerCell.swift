//
//  PlayerCell.swift
//  TapRoyale
//
//  Created by Zac Holland on 5/1/18.
//  Copyright © 2018 Appdojo. All rights reserved.
//

import UIKit

class PlayerCell: UICollectionViewCell {
    // outlets to the UI elements
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var healthBar: UIProgressView!
    @IBOutlet weak var image: UIImageView!
    // attribute to hold the uuid for the player this cell represents
    var uuid: String = ""
}
