//
//  MultipeerConnection.swift
//  Assignment5
//
//  Created by Joe Kickass on 5/5/17.
//  Copyright (c) 2017 Joe Kickass. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

/*
Contains all the connections for multipeer connectivity. These should be established with the MultipeerBrowserViewController class. After the connections are estalished, they reside here and the other class is no longer necessary.

Works by messaging. It sends a string to all connected peers, including itself with the sendString method.
Once a string is send, receiveString is called on all peers, including itself, with the string of interest and the peerID of the sender.
*/
class MultipeerConnection: NSObject, MCSessionDelegate {
    var session: MCSession!
    var peerID: MCPeerID!
    
    
    var myData:[[String]] = []
    
    func receiveString(string: [String], id: MCPeerID) -> [String] {
        // Called for all peers whenever a string is sent by any peer.
        
        // Suggestion: Make QuizGame a member variable in this class, and use it to call a "receiveString" method in QuizGame. Have that method do all the handling necessary.
        
        // Suggestion2: Since sendString sends to all peers, including itself, maybe use that to implement all quizzing functionality, even in single player?
        var result = string
        result.insert(id.displayName, at: 0)
        self.myData.append(result)
        return result
    }
    
    func getData() -> [[String]] {
        return self.myData
    }
    
    func setData(data: [[String]]) {
        self.myData = data
    }
    
    
    override init() {
        super.init()
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
    }
    
    func sendString(string: [String]) {
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: string)
        do{
            try session.send(dataToSend, toPeers: session.connectedPeers, with: .reliable)
        }
        catch let err {
            print("Error in sending data \(err)")
        }
//        receiveString(string: string, id: peerID)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async(execute: {
            if let receivedString = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [String] {
                self.receiveString(string: receivedString, id: peerID)
            }
        })
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
}
