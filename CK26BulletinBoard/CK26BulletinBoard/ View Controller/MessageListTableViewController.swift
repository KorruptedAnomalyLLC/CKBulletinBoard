//
//  MessageListTableViewController.swift
//  CK26BulletinBoard
//
//  Created by Karl Pfister on 6/3/19.
//  Copyright © 2019 Karl Pfister. All rights reserved.
//

import UIKit

class MessageListTableViewController: UITableViewController {
    @IBOutlet weak var messageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load
        MessageController.SharedInstance.fetchMessages { (karlIsAwesome) in
            if karlIsAwesome {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return MessageController.SharedInstance.messages.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)

      let message = MessageController.SharedInstance.messages[indexPath.row]
        cell.textLabel?.text = message.text
        // Need to add detail
        cell.detailTextLabel?.text = DateFormatter.localizedString(from: message.timestamp, dateStyle: .medium, timeStyle: .short)

        return cell
    }
    

   
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let message = MessageController.SharedInstance.messages[indexPath.row]
            
            MessageController.SharedInstance.removeMessage(message: message) { (success) in
                if success {
                    DispatchQueue.main.async {
                        
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }
   
    @IBAction func postButtonTapped(_ sender: Any) {
        guard let messageText = messageTextField.text else { return}
        MessageController.SharedInstance.createMessage(text: messageText, timestamp: Date())
    }
}
