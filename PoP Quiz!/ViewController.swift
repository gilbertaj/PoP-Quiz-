//
//  ViewController.swift
//  PoP Quiz!
//
//  Created by Andrew Gilbert on 5/4/17.
//  Copyright © 2017 Andrew Gilbert. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    @IBOutlet weak var titleLabel: UIImageView!
    @IBOutlet weak var gameModeSelect: UISegmentedControl!
    
    @IBOutlet weak var startQuizButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
        self.browser = MCBrowserViewController(serviceType: "QuizGame", session: session)
        self.assistant = MCAdvertiserAssistant(serviceType: "QuizGame", discoveryInfo: nil, session: session)
        
        assistant.start()
        session.delegate = self
        browser.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startQuiz(_ sender: Any) {
        if(gameModeSelect.selectedSegmentIndex == 0) {
            self.performSegue(withIdentifier: "QuizGame", sender: self)
        } else {
            if(session.connectedPeers.count != 0) {
                self.performSegue(withIdentifier: "QuizGame", sender: self)
            }
        }
        
    }
    
    @IBAction func startConnect(_ sender: Any) {
        present(browser, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "QuizGame") {
            if let vc = segue.destination as? QuizGame {
                vc.player1ID = session.myPeerID.displayName
                vc.connection = self.session
                vc.numberOfPlayers = 1 + session.connectedPeers.count
                print("Got Here")
                if(session.connectedPeers.count != 0) {
                    for i in 1...session.connectedPeers.count {
                        if(i == 1) {
                            vc.player2ID = session.connectedPeers[i-1].displayName
                        }
                        if(i == 2) {
                            vc.player3ID = session.connectedPeers[i-1].displayName
                        }
                        if(i == 3) {
                            vc.player4ID = session.connectedPeers[i-1].displayName
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    func myReadData() {
        let urlString = "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz1.json"
        let url = URL(string: urlString)
        let session = URLSession.shared
        print("Func Loaded")
        let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
            if let result = data {
                print("IN DA DATAS!")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: result, options: .allowFragments)
                    
                    if let dictionary = json as? [String: AnyObject] {
                        var count = dictionary["numberOfQuestions"] as? Int
                        if(count == nil) {
                            count = -1
                        }
                        print("\(count!)")
                    }
                } catch {
                    print("error")
                }
            }
        })
        task.resume()
    }
    
    
    
    
    
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func sendString(string: [String]) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    
}

