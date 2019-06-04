//
//  MessageController.swift
//  CK26BulletinBoard
//
//  Created by Karl Pfister on 6/3/19.
//  Copyright © 2019 Karl Pfister. All rights reserved.
//

import Foundation
import CloudKit
class MessageController {
    
    // Singleton
    static let SharedInstance = MessageController()
    // SoT
    var messages: [Message] = []
    // database
    let privateDB = CKContainer.default().privateCloudDatabase
    // CRUD
    // Create
    func createMessage(text: String, timestamp: Date, completion: @escaping (Bool) -> Void) {
        let message = Message(text: text, timestamp: timestamp)
        //
        self.saveMessage(message: message, completion: completion)
        
    }
    // Remove - Delete
    
    func removeMessage(message: Message, completion: @escaping (Bool) -> ()) {
        
        // Remove locally
        guard let index = MessageController.SharedInstance.messages.firstIndex(of:message) else {return}
        MessageController.SharedInstance.messages.remove(at: index)
        
        // Remove the cloud
        privateDB.delete(withRecordID: message.ckRecordID) { (_, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion(false)
                return
            } else {
                print("Message deleted!! yay!")
                completion(true)
            }
        }
    }
    // Save
    
    func saveMessage(message: Message, completion: @escaping (Bool) -> ()){
        let messageRecord = CKRecord(message: message)
        privateDB.save(messageRecord) { (record, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion(false)
                return
            }
            // record
            guard let record = record, let message = Message(ckRecord: record) else {completion(false); return}
            self.messages.append(message)
            completion(true)
        }
    }
    
    // Load
    func fetchMessages(completion: @escaping (Bool) -> ()){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Constants.recordKey, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion(false)
                return
            }
            // Record
            guard let records = records else {completion(false); return}
            var messages = records.compactMap({Message(ckRecord: $0)})
            messages.sort { $0.timestamp > $1.timestamp }
            self.messages = messages
            completion(true)
        }
    }
    
    func subscribeToNotifications(completion: @escaping (Error?) -> Void) {
        
        //        let predicate = NSPredicate(format: "username == %@", "wsalcedo")
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(recordType: Constants.recordKey, predicate: predicate, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New post! Would you look at that?!"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        privateDB.save(subscription) { (_, error) in
            if let error = error {
                print("Subscription did not save: \(error.localizedDescription)")
                completion(error)
                return
            }
        }
    }
    
    func requestDiscoverabilityAuth(completion: @escaping (CKContainer_Application_PermissionStatus, Error?) -> Void) {
        
        CKContainer.default().status(forApplicationPermission: .userDiscoverability) { (status, error) in
            guard status != .granted else { completion(.granted, error); return }
            
            CKContainer.default().requestApplicationPermission(.userDiscoverability, completionHandler: completion)
        }
    }
    
    func fethAllDiscoverableUsers(completion: @escaping ([CKUserIdentity], Error?) -> Void) {
        
        let discoverIdentities = CKDiscoverAllUserIdentitiesOperation()
        
        var discoveredIds: [CKUserIdentity] = []
        
        discoverIdentities.userIdentityDiscoveredBlock = { identity in
            discoveredIds.append(identity)
        }
        
        discoverIdentities.discoverAllUserIdentitiesCompletionBlock = { error in
            completion(discoveredIds, error)
        }
        
        CKContainer.default().add(discoverIdentities)
        
    }
    
    func fetchUserIdentityWith(email: String, completion: @escaping (CKUserIdentity?, Error?) -> Void) {
        
        CKContainer.default().discoverUserIdentity(withEmailAddress: email, completionHandler: completion)
        
    }
    
}// End of class
