//
//  ViewController.swift
//  Family Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
    // Declare instance variables here
    var messageArray    = [Message]()
    var message         = Message()
    
    // We've pre-linked the IBOutlets
    @IBOutlet var messageHeightConstraint:  NSLayoutConstraint!
    @IBOutlet var sendButton:               UIButton!
    @IBOutlet var messageTextfield:         UITextField!
    @IBOutlet var messageTableView:         UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set yourself as the delegate and datasource here:
        messageTableView.delegate      = self
        messageTableView.dataSource    = self
        
        messageTextfield.delegate      = self

        // Configure table cell heigth
        configureTableCellHeight()
        
        // Setup  user name
        message.sender = (Auth.auth().currentUser?.email)!
       
        // Add notification for keyboard heigth change
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification,object:nil)
        
        // Add tap gesture to dismiss keyboard when user tap on the view controller (out of the keyboard)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Launch retrieve message observer
        retrieveMessageFromFirebase()
        
        // hides back navigation item
        self.navigationItem.setHidesBackButton(true, animated:true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    ///////////////////////////////////////////
    //MARK: - TableView DataSource Methods
    
    //Declare cellForRowAtIndexPath here: 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.messageTime.text = messageArray[indexPath.row].time
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.receiverAvatarImageView.image = UIImage.init(named: "egg")
        cell.senderAvatarImageView.image = UIImage.init(named: "egg")
        
        if message.sender == messageArray[indexPath.row].sender {
            cell.receiverAvatarImageView.isHidden = true
            cell.senderAvatarImageView.isHidden = false
            cell.messageBackground.backgroundColor = UIColor.flatMint()
            cell.messageBody.textColor = UIColor.flatWhite()
            cell.senderUsername.textColor = UIColor.flatBlack()
            
        } else {
            cell.receiverAvatarImageView.isHidden = false
            cell.senderAvatarImageView.isHidden     = true
            cell.messageBackground.backgroundColor = UIColor.flatWhite()
            cell.messageBody.textColor = UIColor.flatBlack()
            cell.senderUsername.textColor = UIColor.flatGray()
        }
        
        return cell
    }
    
    
    //Declare numberOfRowsInSection here:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }

    //Configure heigth of the table cells:
    func configureTableCellHeight(){
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    ///////////////////////////////////////////
    //MARK: - TableView Utility Methods
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messageArray.count-1, section: 0)
            self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    ///////////////////////////////////////////
    //MARK:- keyboard Notification
    
    @objc func keyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame!.origin.y
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.messageHeightConstraint.constant = 50 //heigth of the message view when it's on the bottom side

            } else {
                self.messageHeightConstraint?.constant = endFrame?.size.height ?? 50
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: .curveLinear,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    
    ////////////////////////////////////////////
    //MARK:- dismiss keyboard
    
    // dismiss keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    ///////////////////////////////////////////
    //MARK: - Send button action on keyboard and on textbar
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        sendMessageToFirebase()
        return false
    }
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        dismissKeyboard()
        sendMessageToFirebase()
    }
    
    ///////////////////////////////////////////
    //MARK: - Send & Recieve from Firebase
    
    // Send message to Firebase and save it in database
    func sendMessageToFirebase (){
        
        if messageTextfield.text != ""{
            
            let date = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)

            sendButton.isEnabled =          false
            messageTextfield.isEnabled =    false
            
            message.messageBody = messageTextfield.text!
            message.time = "\(hour):\(minutes)"
            let messageDBRef = Database.database().reference().child("Messages")
            
            messageDBRef.childByAutoId().setValue(["messageBody": message.messageBody, "sender":message.sender, "time":message.time]){
                (error, dbRef) in
                if error != nil {
                    print("Error saving message on database \(String(describing: error))")
                } else {                    
                    self.sendButton.isEnabled = true
                    self.messageTextfield.isEnabled = true
                    self.messageTextfield.text = ""
                }
            }
        }
    }
    
    //Create the retrieveMessages method here:
    func retrieveMessageFromFirebase(){
        
        let messageDBRef = Database.database().reference().child("Messages")

        messageDBRef.observe(.childAdded) { snapshot in
            let snapshotValue = snapshot.value as! Dictionary<String,String>
            
            let message = Message()
            message.messageBody  = snapshotValue["messageBody"]!
            message.sender       = snapshotValue["sender"]!
            message.time         = snapshotValue["time"]!
            self.messageArray.append(message)
            
            self.messageTableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        //TODO: Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        }
        catch {
            print("Error during log out")
        }
    }
    
}
