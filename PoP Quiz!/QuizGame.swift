//
//  QuizGame.swift
//  PoP Quiz!
//
//  Created by Andrew Gilbert on 5/4/17.
//  Copyright © 2017 Andrew Gilbert. All rights reserved.
//

import MultipeerConnectivity
import QuartzCore
import UIKit

class QuizGame: UIViewController, MCSessionDelegate {
    
    public var connection: MCSession!
    var myData:[[String]] = []
    public var player1ID = ""
    public var player2ID = ""
    public var player3ID = ""
    public var player4ID = ""
    
    @IBOutlet weak var player1Answer: UILabel!
    @IBOutlet weak var player2Answer: UILabel!
    @IBOutlet weak var player3Answer: UILabel!
    @IBOutlet weak var player4Answer: UILabel!
    @IBOutlet weak var player1Image: UIImageView!
    @IBOutlet weak var player2Image: UIImageView!
    @IBOutlet weak var player3Image: UIImageView!
    @IBOutlet weak var player4Image: UIImageView!
    @IBOutlet weak var player1Score: UILabel!
    @IBOutlet weak var player2Score: UILabel!
    @IBOutlet weak var player3Score: UILabel!
    @IBOutlet weak var player4Score: UILabel!
    @IBOutlet weak var QuestionLabel: UILabel!
    @IBOutlet weak var answerALabel: UILabel!
    @IBOutlet weak var answerBLabel: UILabel!
    @IBOutlet weak var answerCLabel: UILabel!
    @IBOutlet weak var answerDLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var restartQuizButton: UIButton!
    
    
    //Used with the json files.
    //Quiznumber determines which online json file to get.
    //questions is the array of dictionaries from the json file.
    //currentQuestion and currentCorrectCorrectOption are update from questions at each getNextQuestion()
    private var quizNumber = 1
    private var questions: [[String: AnyObject]] = []
    private var currentQuestion = 0
    private var currentCorrectOption = "A"
    private var topic = "General"
    
    
    //Variables used for quiz game
    //selected and didSubmit to tell if this user has selected or submitted
    //Time is higher because 1 second at the begining is spent reading data
    //submitted is how many out of all players have submitted
    //isFinish is true when the quiz has finished. While it is set to true the updateTime() func will not do anything. This is so that the readData task has time to finish.
    public var numberOfPlayers = 1
    private var time = 22
    private var selected = false
    private var didSubmit = false
    private var answerSelected = ""
    private var isFinish = true
    
    private var player1score = 0
    private var player2score = 0
    private var player3score = 0
    private var player4score = 0
    
    private var player1answer = ""
    private var player2answer = ""
    private var player3answer = ""
    private var player4answer = ""
    
    private var coreMotion = MotionSystem()
    
    private var submitted = 0
    private var ready = 0
    private var ended = 0
    
    private var player1ready = false
    private var player2ready = false
    private var player3ready = false
    private var player4ready = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coreMotion = MotionSystem()
        connection.delegate = self
        
        
        //Disabled so that readData task can finish
        self.view.isUserInteractionEnabled = false
        
        //makes restartButton hidden and gives the answer options rounded corners
        restartQuizButton.isHidden = true
        answerALabel.layer.masksToBounds = true
        answerALabel.layer.cornerRadius = 5
        answerBLabel.layer.masksToBounds = true
        answerBLabel.layer.cornerRadius = 5
        answerCLabel.layer.masksToBounds = true
        answerCLabel.layer.cornerRadius = 5
        answerDLabel.layer.masksToBounds = true
        answerDLabel.layer.cornerRadius = 5
        
        setPlayersImages()
        
        
        readData(num: quizNumber)
        
        //calls updateTime every second
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkCoreMotion), userInfo: nil, repeats: true)
        
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(getConnectionData), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Sets inactive players to be mostly transparent
    func setPlayersImages() {
        if (numberOfPlayers < 4) {
            player4Image.alpha = 0.2
        }
        if (numberOfPlayers < 3) {
            player3Image.alpha = 0.2
        }
        if (numberOfPlayers < 2) {
            player2Image.alpha = 0.2
        }
    }
    
    //Reads Json data from http://www.people.vcu.edu/~ebulut/jsonFiles/quiz(quizNumber).json
    //The first part creates the url from the String and the quizNumber
    //The second part creates the download task and runs it. If the json file is valid then its questions and topic are stored. and isFinished is set to false.
    //If the json file is not valid then it prints "ERROR" and the quiz number is set to zero. This causes updateTime() to rerun readData with a quizNumber of 1.
    func readData(num: Int) {
        let urlString = "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz" + "\(num)" + ".json"
        
        let url = URL(string: urlString)
        let session = URLSession.shared
        
        let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
            if let result = data {
                
                do {
                    let json = try JSONSerialization.jsonObject(with: result, options: .allowFragments)
                    
                    if let dictionary = json as? [String: AnyObject] {
                        self.topic = dictionary["topic"] as! String
                        let array = dictionary["questions"] as? [[String:AnyObject]]
                        self.questions = array!
                        self.isFinish = false
                        self.ready += 1
                        self.player1ready = true
                        self.sendString(string: [self.player1ID, "READY"])
                    }
                } catch {
                    print("ERROR")
                    self.quizNumber = 0
                    
                }
            }
        })
        task.resume()
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //This block of functions is responsible for running the game, getting the questions, updating labels and time, and finishing the game.
    
    //updateTime() subtracts 1 from time normally. If is isFinished is true then it does nothing unless quizNumber = 0. If time is already 0 then it stops displaying the current time. At 21 it enables user interaction after the new Quiz is loaded in. At 0 it calls finishQuestion() and at -3 it resest time to 20, resets submit and selected variables, and calls the next question.
    func updateTime() {
        if(quizNumber == 0) {
            restartAction(self)
            return
        }
        if(ready < numberOfPlayers) {
            return
        }
        
        if(isFinish) {
            finish()
            return
        }
        
        time -= 1
        if(time > -1) {
            timeLabel.text = "\(time)"
        }
        if(time == 21) {
            self.view.isUserInteractionEnabled = true
            self.title = topic
            time = 20
            timeLabel.text = "\(time)"
            getNextQuestion()
            return
        }
        
        if(time == 0) {
            finishQuestion()
            return
        }
        
        if(time < -3) {
            currentQuestion += 1
            setBackgroundColor(id: answerSelected)
            answerSelected = ""
            time = 20
            timeLabel.text = "\(time)"
            selected = false
            didSubmit = false
            getNextQuestion()
        }
    }
    
    func checkCoreMotion() {
        if(didSubmit) {
            return
        }
        //Checking coreMotion each 10nth of a second
        let test = coreMotion.getSelected()
        if(test == "RIGHT") {
            moveSelectionRight()
            coreMotion.setSelected(select: "")
        } else if(test == "LEFT") {
            moveSelectionLeft()
            coreMotion.setSelected(select: "")
        } else if(test == "UP") {
            moveSelectionUp()
            coreMotion.setSelected(select: "")
        } else if(test == "DOWN") {
            moveSelectionDown()
            coreMotion.setSelected(select: "")
        } else if(test == "SUBMIT") {
            if(selected) {
                submit()
                coreMotion.setSelected(select: "")
            }
        }
        coreMotion.setSelected(select: "")
    }
    
    //Runs when the quiz is done. It calculates the player with the highest score and sets them to the winner. Sets isFinish to true and makes the restartQuiz button visible
    func finish() {
        self.sendString(string: [self.player1ID, "ENDED"])
        isFinish = true
        ended += 1
        
        if(ended < numberOfPlayers) {
            return
        }
        let high = max(player1score, player2score, player3score, player4score)
        if(player1score == high) {
            timeLabel.text = "YOU WON"
        } else if(player2score == high) {
            timeLabel.text = "PLAYER 2 WON"
        }else if(player3score == high) {
            timeLabel.text = "PLAYER 3 WON"
        }else {
            timeLabel.text = "PLAYER 4 WON"
        }
        
        if(player1score == 0) {
            timeLabel.text = "YOU LOSE"
        }
        
        currentQuestion = 0
        restartQuizButton.isHidden = false
    }
    
    //Gets the next question in the quiz. If the quiz is out of questions then it calls finish(). Updates labels and currentCorrectOption with new question values
    func getNextQuestion() {
        if(currentQuestion == questions.count) {
            finish()
            return
        }
        let array = questions[currentQuestion]["options"] as! [String: String]
        QuestionLabel.text = questions[currentQuestion]["questionSentence"] as? String
        answerALabel.text = array["A"]
        answerBLabel.text = array["B"]
        answerCLabel.text = array["C"]
        answerDLabel.text = array["D"]
        currentCorrectOption = questions[currentQuestion]["correctOption"] as! String
    }
    
    //checks to see how many players have submitted.
    func checkSubmit() {
        
        //Put multipeer stuff here maybe?
        
        if(numberOfPlayers - submitted < 1) {
            time = 0
            finishQuestion()
        }
    }
    
    //Runs when the question is fully submitted or time hits 0. It displays the correct option and updates player score
    func finishQuestion() {
        timeLabel.text = currentCorrectOption
        player1Answer.text = player1answer
        player2Answer.text = player2answer
        player3Answer.text = player3answer
        player4Answer.text = player4answer
        
        if(answerSelected == currentCorrectOption && didSubmit) {
            player1score += 1
        }
        self.sendString(string: [player1ID, "SCORE", String(player1score)])
        updateScores()
        submitted = 0
    }
    
    //checks to see players scores and updates the labels
    func updateScores() {
        
        //Put multipeer stuff here maybe?
        
        player1Score.text = String(player1score)
        player2Score.text = String(player2score)
        player3Score.text = String(player3score)
        player4Score.text = String(player4score)
    }
    
    //Run when the restart Quiz button is pressed. It resets the game and calls readData wih the new quizNumber
    @IBAction func restartAction(_ sender: Any) {
        submitted = 0
        ended = 0
        if(quizNumber != 0) {
            ready = 0
        }
        restartQuizButton.isHidden = true
        currentQuestion = 0
        quizNumber += 1
        time = 22
        player1score = 0
        player2score = 0
        player3score = 0
        player4score = 0
        player1ready = false
        player2ready = false
        player3ready = false
        player4ready = false
        player1Score.text = "0"
        player2Score.text = "0"
        player3Score.text = "0"
        player4Score.text = "0"
        self.view.isUserInteractionEnabled = false
        readData(num: quizNumber)
    }
    
    func getConnectionData() {
        if(myData.count == 0) {
            return
//            print("Here")
        }
        
        for i in 0...(myData.count-1) {
            if(myData[i][0] == player2ID) {
                if(myData[i][1] == "READY" && !player2ready) {
                    ready += 1
                    player2ready = true
                    if(player1ready) {
                        sendString(string: [player1ID, "READY"])
                    }
                } else if(myData[i][1] == "SUBMIT") {
                    submitted += 1
                    player2answer = myData[i][2]
                    checkSubmit()
                } else if(myData[i][1] == "SCORE") {
                    player2score = Int(myData[i][2])!
                    updateScores()
                } else if(myData[i][1] == "ENDED") {
                    ended += 1
                }
                
                
            } else if(myData[i][0] == player3ID) {
                if(myData[i][1] == "READY" && !player3ready) {
                    ready += 1
                    player3ready = true
                    if(player1ready) {
                        sendString(string: [player1ID, "READY"])
                    }
                } else if(myData[i][1] == "SUBMIT") {
                    submitted += 1
                    player3answer = myData[i][2]
                    checkSubmit()
                } else if(myData[i][1] == "SCORE") {
                    player3score = Int(myData[i][2])!
                    updateScores()
                } else if(myData[i][1] == "ENDED") {
                    ended += 1
                }
                
                
            } else if(myData[i][0] == player4ID) {
                if(myData[i][1] == "READY" && !player4ready) {
                    ready += 1
                    player4ready = true
                    if(player1ready) {
                        sendString(string: [player1ID, "READY"])
                    }
                } else if(myData[i][1] == "SUBMIT") {
                    submitted += 1
                    player3answer = myData[i][2]
                    checkSubmit()
                } else if(myData[i][1] == "SCORE") {
                    player3score = Int(myData[i][2])!
                    updateScores()
                } else if(myData[i][1] == "ENDED") {
                    ended += 1
                }
                
                
            }
        }
        myData = []
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //This block of code is responsible for managing the player answer selection
    
    //Figures out which answer was clicked and calls its function. If this player has submitted then it returns without doing anything.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLoaction = touch!.location(in: self.view)
        
        if(didSubmit) {
            return
        }
        var testFrame = self.view.convert(answerALabel.frame, from: answerALabel.superview)
        if (testFrame.contains(touchLoaction)) {
            answerATapped()
        }
        testFrame = self.view.convert(answerBLabel.frame, from: answerBLabel.superview)
        if (testFrame.contains(touchLoaction)) {
            answerBTapped()
        }
        testFrame = self.view.convert(answerCLabel.frame, from: answerCLabel.superview)
        if (testFrame.contains(touchLoaction)) {
            answerCTapped()
        }
        testFrame = self.view.convert(answerDLabel.frame, from: answerDLabel.superview)
        if (testFrame.contains(touchLoaction)) {
            answerDTapped()
        }
    }
    
    func answerATapped() {
        if(!selected) {
            answerALabel.backgroundColor = UIColor.cyan
            selected = true
            answerSelected = "A"
        } else if(answerSelected == "A") {
            answerALabel.backgroundColor = UIColor.green
            submit()
        } else {
            answerALabel.backgroundColor = UIColor.cyan
            setBackgroundColor(id: answerSelected)
            answerSelected = "A"
        }
    }
    
    func answerBTapped() {
        if(!selected) {
            answerBLabel.backgroundColor = UIColor.cyan
            selected = true
            answerSelected = "B"
        } else if(answerSelected == "B") {
            answerBLabel.backgroundColor = UIColor.green
            submit()
        } else {
            answerBLabel.backgroundColor = UIColor.cyan
            setBackgroundColor(id: answerSelected)
            answerSelected = "B"
        }
    }
    
    func answerCTapped() {
        if(!selected) {
            answerCLabel.backgroundColor = UIColor.cyan
            selected = true
            answerSelected = "C"
        } else if(answerSelected == "C") {
            answerCLabel.backgroundColor = UIColor.green
            submit()
        } else {
            answerCLabel.backgroundColor = UIColor.cyan
            setBackgroundColor(id: answerSelected)
            answerSelected = "C"
        }
    }
    
    func answerDTapped() {
        if(!selected) {
            answerDLabel.backgroundColor = UIColor.cyan
            selected = true
            answerSelected = "D"
        } else if(answerSelected == "D") {
            answerDLabel.backgroundColor = UIColor.green
            submit()
        } else {
            answerDLabel.backgroundColor = UIColor.cyan
            setBackgroundColor(id: answerSelected)
            answerSelected = "D"
        }
    }
    
    //sets answer backgrounds back to light grey
    func setBackgroundColor(id: String) {
        if(id == "A") {
            answerALabel.backgroundColor = UIColor.lightGray
        } else if (id == "B") {
            answerBLabel.backgroundColor = UIColor.lightGray
        } else if (id == "C") {
            answerCLabel.backgroundColor = UIColor.lightGray
        } else {
            answerDLabel.backgroundColor = UIColor.lightGray
        }
    }
    
    //sets this player to have submitted and calls checkSubmit()
    func submit() {
        submitted += 1
        didSubmit = true
        
        self.sendString(string: [player1ID, "SUBMIT", answerSelected])
        
        checkSubmit()
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //Implementing the CoreMotion and added device shake
    
    
    func moveSelectionRight() {
        if(answerSelected == "A") {
            answerBTapped()
        } else if(answerSelected == "C") {
            answerDTapped()
        }
    }
    
    func moveSelectionLeft() {
        if(answerSelected == "B") {
            answerATapped()
        } else if(answerSelected == "D") {
            answerCTapped()
        }
    }
    
    func moveSelectionUp() {
        if(answerSelected == "C") {
            answerATapped()
        } else if(answerSelected == "D") {
            answerBTapped()
        }
    }
    
    func moveSelectionDown() {
        if(answerSelected == "A") {
            answerCTapped()
        } else if(answerSelected == "B") {
            answerDTapped()
        }
    }
    
    //Checks to see if the device was shook
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (motion == .motionShake) {
            let values = ["A", "B", "C", "D"]
            var success = false
            while(!success) {
                let test = values[Int(arc4random_uniform(4))]
                if(test != answerSelected) {
                    success = true
                    setBackgroundColor(id: answerSelected)
                    answerSelected = test
                    selected = true
                    if(test == "A") {
                        answerALabel.backgroundColor = UIColor.cyan
                    } else if(test == "B") {
                        answerBLabel.backgroundColor = UIColor.cyan
                    } else if(test == "C") {
                        answerCLabel.backgroundColor = UIColor.cyan
                    } else {
                        answerDLabel.backgroundColor = UIColor.cyan
                    }
                    
                }
            }
        }
    }
    
    
    
    
    
    
    
    func receiveString(string: [String], id: MCPeerID) {
//        var result = string
//        result.insert(id.displayName, at: 0)
//        print(result)
        self.myData.append(string)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func sendString(string: [String]) {
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: string)
        do{
            try self.connection.send(dataToSend, toPeers: connection.connectedPeers, with: .unreliable)
        }
        catch let err {
            //print("Error in sending data \(err)")
        }
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
