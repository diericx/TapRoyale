//
//  ViewController.swift
//  TapRoyale
//
//  Created by Zac Holland on 5/1/18.
//  Copyright © 2018 Appdojo. All rights reserved.
//

import UIKit

// Main menu view controller
class MenuVC: UIViewController {

    @IBOutlet weak var usernameInput: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is GameVC
        {
            let vc = segue.destination as? GameVC
            vc?.uuid = usernameInput.text!
        }
    }

    // Callback for Join Game button
    @IBAction func onJoinGameButtonUpInside(_ sender: Any) {
        if (usernameInput.text == "") {
            return
        }
        performSegue(withIdentifier: "segue_menuToGame", sender: nil)
    }
    
}

