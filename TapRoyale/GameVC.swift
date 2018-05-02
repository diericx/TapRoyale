//
//  GameVC.swift
//  TapRoyale
//
//  Created by Zac Holland on 5/1/18.
//  Copyright © 2018 Appdojo. All rights reserved.
//

import UIKit
import PubNub

var gameChannel = "game"

struct PlayerState {
    var health: Int = 100
    var ready: Bool = false
}

struct GameState {
    var status = "waiting"
    var totalPlayers = 0
    var activePlayers = 0
}

class GameVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PNObjectEventListener {
    
    @IBOutlet weak var serverInfoText: UILabel!
    @IBOutlet weak var attackButton: UIButton!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var playersCollectionView: UICollectionView!
    
    var targetPlayerUUID = ""
    var uuid = "default-uuid"
    var winnerUuid = ""
    
    var playerStates = [String: PlayerState]()
    var gameState = GameState()
    
    // ------------------------
    // --- Overrides ----------
    // ------------------------
    
    // Stores reference on PubNub client to make sure what it won't be released.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reinitiate pubnub and reset the UI
        initPubNub()
//        updateUI()
    }
    
    // Unsubscribe from pubnub when view changes
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Reset
        playerStates = [String: PlayerState]()
        gameState = GameState()
        targetPlayerUUID = ""
        
        // Unsubscribe from the game channel so everyone knows we have left
        print("Bye pubnub!")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.unsubscribeFromChannels([gameChannel], withPresence: true)
        appDelegate.client?.removeListener(self)
    }
    
    // Before segue, set the label describing who won
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is WinVC
        {
            let vc = segue.destination as? WinVC
            vc?.winLabelText = self.winnerUuid + " Won!"
        }
    }
    
    // ------------------------
    // --- Actions ------------
    // ------------------------
    
    // When the attack button is pressed, attempt to attack the targeted player
    // This only works if the user has selected a target
    @IBAction func attackButtonOnUpInside(_ sender: Any) {
        if (targetPlayerUUID == "") {
            print("No target to attack!")
            return
        }
        sendMessage(packet: "{\"action\": \"attack\", \"uuid\": \"\(uuid)\", \"targetUuid\": \"\(targetPlayerUUID)\"}")
    }
    
    // Send the ready message
    @IBAction func readyButtonOnUpInside(_ sender: Any) {
        sendMessage(packet: "{\"action\": \"ready\", \"uuid\": \"\(uuid)\"}")
    }
    
    // ------------------------
    // --- PubNub -------------
    // ------------------------
    
    // Initialize pubnub client
    func initPubNub() {
        print("Initializing PubNub")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.client?.unsubscribeFromChannels([gameChannel], withPresence: true) // If pubnub exists, unsubscribe
        
        
        let config = PNConfiguration( publishKey: "pub-key", subscribeKey: "sub-key")
        config.uuid = uuid
        config.presenceHeartbeatValue = 30
        config.presenceHeartbeatInterval = 10
        
        appDelegate.client = PubNub.clientWithConfiguration(config)
        
        appDelegate.client?.addListener(self)
        
        appDelegate.client?.subscribeToChannels([gameChannel], withPresence: true)
        //
        appDelegate.client?.timeWithCompletion({ (result, status) in
                if status == nil {
                    print("Connected!")
                    self.sendMessage(packet: "{\"action\": \"join\", \"uuid\": \"\(self.uuid)\"}")
//                    self.getPlayersHereNow()
                }
                else {
                    status?.retry()
                }
            })
    }
    
    // Handle new message from one of channels on which client has been subscribed.
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        
        let parsedMessage: AnyObject = message.data.message as AnyObject;
        let action: String = parsedMessage["action"] as! String
        if action == "updateGameState" {
            // Get objects from message
            let gameState: AnyObject = parsedMessage["gameState"] as AnyObject
            let playerStates: [String: AnyObject] = gameState["playerStates"] as! [String: AnyObject]
            // Update game status
            self.gameState.status = gameState["status"] as! String
            self.gameState.totalPlayers = gameState["totalPlayers"] as! Int
            self.gameState.activePlayers = gameState["activePlayers"] as! Int
            // Update player states
            for stateObj in playerStates {
                // Get user's state
                let uuid = stateObj.key
                let state = stateObj.value as! [String: AnyObject]
                // get user's info
                let health = state["health"] as! Int
                let ready = state["ready"] as! Bool
                // Update the player states
                if (self.playerStates[stateObj.key] == nil) {
                    self.playerStates[stateObj.key] = PlayerState()
                }
                self.playerStates[stateObj.key]?.health = health
                self.playerStates[stateObj.key]?.ready = ready
            }
        } else if action == "updatePlayerState" {
            let uuid = parsedMessage["uuid"] as! String
            let playerState = parsedMessage["playerState"] as! [String: AnyObject]
            self.playerStates[uuid]?.health = playerState["health"] as! Int
            self.playerStates[uuid]?.ready = playerState["ready"] as! Bool
        } else if action == "startGame" {
            gameState.status = "inProgress"
        } else if action == "ready" {
            let uuid = parsedMessage["uuid"] as! String
            self.playerStates[uuid]?.ready = true
        } else if action == "win" {
            let uuid = parsedMessage["uuid"] as! String
            self.winnerUuid = uuid
            performSegue(withIdentifier: "segue_gameToWinScreen", sender: nil)
        } else {
            return
        }
        updateUI()
    }
    
    // Helper function for sending messages
    func sendMessage(packet: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.publish(packet, toChannel: gameChannel, compressed: false)
    }
    
    // ------------------------
    // --- UI -----------------
    // ------------------------
    
    func updateUI() {
        updateActionButtonsVisibility()
        playersCollectionView.reloadData()
        if gameState.status == "waiting" {
            serverInfoText.text = "Waiting for all players to ready uo..."
        } else if gameState.status == "inProgress" {
            let playersLeft = gameState.totalPlayers - (gameState.totalPlayers - gameState.activePlayers)
            serverInfoText.text = "\(playersLeft) Player(s) Left."
        }
    }
    
    // Set the action button visibility according to the game state
    func updateActionButtonsVisibility() {
        if gameState.status == "waiting" {
            readyButton.isEnabled = true
            attackButton.isHidden = true
            if (playerStates[uuid] != nil && playerStates[uuid]!.ready ) {
                readyButton.isEnabled = false
            }
        } else {
            attackButton.isHidden = false
            readyButton.isHidden = true
        }
    }
    
    // ------------------------
    // --- Table View ---------
    // ------------------------
    
    // Set the table view's cell count to the amount of player states
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playerStates.count
    }
    
    // Populate each cell with data for a player
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Get the cell
        let cell: PlayerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PlayerCell
        
        // Get information from the player states
        let key = Array(playerStates.keys)[indexPath.row]
        let state = playerStates[key]!
        
        // Set attributes of cell to match the player that it represents
        cell.nameLabel.text = key
        cell.healthBar.progress = Float(state.health)/100
        if (state.ready && state.health > 0) {
            cell.image.alpha = 1
        } else {
            cell.image.alpha = 0.5
        }
        
        // Create a red background for when the cell is selected
        let view = UIView(frame: cell.bounds)
        view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        cell.selectedBackgroundView = view
        
        return cell
    }
    
    // When a cell is selected, set the player it represents as the target
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell: PlayerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PlayerCell
        
        let key = Array(playerStates.keys)[indexPath.row]
        targetPlayerUUID = key
    }
    
    
}
