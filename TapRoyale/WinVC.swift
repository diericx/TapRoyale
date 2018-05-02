//
//  WinVC.swift
//  TapRoyale
//
//  Created by Zac Holland on 5/1/18.
//  Copyright © 2018 Appdojo. All rights reserved.
//

import UIKit

// Main menu view controller
class WinVC: UIViewController {
    
    @IBOutlet weak var winLabel: UILabel!
    var winLabelText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        winLabel.text = winLabelText
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onDismissUpInside(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    
}

