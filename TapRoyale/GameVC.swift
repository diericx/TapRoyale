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
}

class GameVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PNObjectEventListener {
    
    @IBOutlet weak var serverInfoText: UILabel!
    @IBOutlet weak var attackButton: UIButton!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var playersCollectionView: UICollectionView!
    
    var targetPlayerUUID = ""
    var uuid = "default-uuid"
    var winnerUuid = ""
    
    var testTableData: [String] = ["Test1", "Test2"]
    var playerStates = [String: PlayerState]()
    var gameState = GameState()
    
    // Stores reference on PubNub client to make sure what it won't be released.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize game state to empty dictionary
        playerStates = [String: PlayerState]()
        targetPlayerUUID = ""
        // Do any additional setup after loading the view, typically from a nib.
        initPubNub()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Unsubscribe from pubnub when view changes
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Unsubscribe from the game channel so everyone knows we have left
        print("Bye pubnub!")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.unsubscribeFromChannels([gameChannel], withPresence: true)
        appDelegate.client?.removeListener(self)
    }
    
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
        
        
        let config = PNConfiguration( publishKey: "pub-c-36290493-5352-4632-90c5-9c94f5d0127c", subscribeKey: "sub-c-9c0c38c8-4dab-11e8-9796-063929a21258")
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
    
    // calls PubNub's hereNowForChannel function to get all users that are
    // currently present in the channel.
    func getPlayersHereNow() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.hereNowForChannel("game", withVerbosity: .state,
                                 completion: { (result, status) in

            if status == nil {
                // Parse out the uuids from the result
                let uuidObjs: AnyObject = result!.data.uuids as AnyObject
                let uuidObjDict = uuidObjs as! [[String:AnyObject]]
                // for each uuid, create a new player in the playerStates object
                for uuidObj in uuidObjDict {
                    let uuid = uuidObj["uuid"] as! String
                    self.playerStates[uuid] = PlayerState()
                }
                // reload the view
                self.playersCollectionView.reloadData()
            }
            else {
                print("ERROR: could not get hereNow")
            }
        })
    }
    
    // Handle new message from one of channels on which client has been subscribed.
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        
        // Handle new message stored in message.data.message
        if message.data.channel != message.data.subscription {
            
            // Message has been received on channel group stored in message.data.subscription.
        }
        else {
            
            // Message has been received on channel stored in message.data.channel.
        }
        
        let parsedMessage: AnyObject = message.data.message as AnyObject;
        let action: String = parsedMessage["action"] as! String
        if action == "updateGameState" {
            // Get objects from message
            let gameState: AnyObject = parsedMessage["gameState"] as AnyObject
            print(gameState)
            let playerStates: [String: AnyObject] = gameState["playerStates"] as! [String: AnyObject]
            // Update game status
            self.gameState.status = gameState["status"] as! String
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
    
    // Handle new presence events
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        
        // Handle presence event event.data.presenceEvent (one of: join, leave, timeout, state-change).
        if event.data.channel != event.data.subscription {
            
            // Presence event has been received on channel group stored in event.data.subscription.
        }
        else {
            
            // Presence event has been received on channel stored in event.data.channel.
        }
        
        if event.data.presenceEvent != "state-change" {
            
            print("\(event.data.presence.uuid) \"\(event.data.presenceEvent)'ed\"\n" +
                "at: \(event.data.presence.timetoken) on \(event.data.channel) " +
                "(Occupancy: \(event.data.presence.occupancy))");
        }
        else {
            
            print("\(event.data.presence.uuid) changed state at: " +
                "\(event.data.presence.timetoken) on \(event.data.channel) to:\n" +
                "\(event.data.presence.state)");
        }
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
    }
    
    // Set the action button visibility according to the game state
    func updateActionButtonsVisibility() {
        if gameState.status == "waiting" {
            attackButton.isHidden = true
            if (playerStates[uuid]!.ready) {
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
