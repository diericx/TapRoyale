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
var testuuid = "test-uuid"

struct PlayerState {
    var health = 100
}

class GameVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PNObjectEventListener {
    
    var testTableData: [String] = ["Test1", "Test2"]
    var playerStates = [String: PlayerState]()
    
    // Stores reference on PubNub client to make sure what it won't be released.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize game state to empty dictionary
        playerStates = [String: PlayerState]()
        // Do any additional setup after loading the view, typically from a nib.
        initPubNub()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Unsubscribe from the game channel so everyone knows we have left
        print("Bye pubnub!")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.unsubscribeFromChannels([gameChannel], withPresence: true)
        appDelegate.client?.removeListener(self)
    }
    
    @IBAction func attackButtonOnUpInside(_ sender: Any) {
        sendMessage(packet: "{\"action\": \"ready\", \"uuid\": \"\(testuuid)\"}")
    }
    
    // --------------
    // --- PubNub Functions ---
    // --------------
    
    // Initialize pubnub client
    func initPubNub() {
        print("Initializing PubNub")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.client?.unsubscribeFromChannels([gameChannel], withPresence: true) // If pubnub exists, unsubscribe
        
        
        let config = PNConfiguration( publishKey: "pub-c-36290493-5352-4632-90c5-9c94f5d0127c", subscribeKey: "sub-c-9c0c38c8-4dab-11e8-9796-063929a21258")
        config.uuid = testuuid
        config.presenceHeartbeatValue = 30
        config.presenceHeartbeatInterval = 10
        
        appDelegate.client = PubNub.clientWithConfiguration(config)
        
        appDelegate.client?.addListener(self)
        
        appDelegate.client?.subscribeToChannels([gameChannel], withPresence: true)
        //
        getPlayersHereNow()
    }
    
    func getPlayersHereNow() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.hereNowForChannel("game", withVerbosity: .state,
                                 completion: { (result, status) in

            if status == nil {
                let uuids: AnyObject = result!.data.uuids as AnyObject;
                print(uuids)
                print(uuids.count)
                for uuid in uuids {
                    let uuidObj: AnyObject = uuid as AnyObject
                    let uuidString = uuid["uuid"] as String
                    playerStates[uuid] = PlayerState()
                }
//                for uuid in result!.data.uuids {
//                    print(uuid)
//                }
                /**
                 Handle downloaded presence information using:
                 result.data.uuids - list of uuids.
                 result.data.occupancy - total number of active subscribers.
                 */
            }
            else {

                /**
                 Handle presence audit error. Check 'category' property to find
                 out possible reason because of which request did fail.
                 Review 'errorData' property (which has PNErrorData data type) of status
                 object to get additional information about issue.

                 Request can be resent using: status.retry()
                 */
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
        print(action)
        if (action == "updateGameState") {
            let playerStates: AnyObject = parsedMessage["playerStates"] as AnyObject
            print(playerStates)
        }
//        if (action == "")
//        print(text)
        
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
    
    func sendMessage(packet: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.client?.publish(packet, toChannel: gameChannel, compressed: false)
    }
    
    
    // --------------
    // --- Table View Functions ---
    // --------------
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return testTableData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PlayerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PlayerCell
        
        cell.nameLabel.text = testTableData[indexPath.row]
        
        return cell
    }
    
    
}
