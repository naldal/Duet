//
//  DatabaseManager.swift
//  Duet
//
//  Created by 송하민 on 2021/07/18.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void))  {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        // To check email is exist, find safeEmail in firebase database, and then check nil for snapshot.
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            // if snapshot is nil, then completion closure argument will be allocated "false"
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            // completion closure argument will be allocated "true"
            completion(true)
        }
    }
    
    /// Insert new user to database
    public func insertUser(with user: DuetUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { error, reference in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    // append to user dictionary
                    usersCollection.append([
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ])
                    
                    self.database.child("users").setValue(usersCollection) { error, ref in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    // create that array
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, ref in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            completion(.success((value)))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFecth
    }
}

// MARK: - Sending messages / conversations

extension DatabaseManager {
    
    /*
     
     "asdfasdfasd" {
     "messages" : [
     {
     "id": String,
     "type": text, photo, video
     "content": String,
     "date": Date(),
     "sender_email": String
     "isRead" : true / fase
     }
     ]
     }
     
     conversations => [
     [
     "conversation_id": "unique_identifier"
     "receiver":
     "latest_message" => {
     "date": Date()
     "latest+message": "message"
     "is_read": true/fase
     }
     ]
     ]
     */
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with receiver: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationsData:[String:Any] = [
                "id": conversationId,
                "receiver": receiver,
                "latest_message": [
                    "data": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                // conversation array exist for current user
                // should append
                conversations.append(newConversationsData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            } else {
                // conversation array doesn't exist
                // should create
                userNode["conversations"] = [
                    newConversationsData
                ]
                
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                    completion(true)
                }
            }
        }
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool)->Void) {
        
        //        {
        //             "id": String,
        //             "type": text, photo, video
        //             "content": String,
        //             "date": Date(),
        //             "sender_email": String
        //             "isRead" : true / fase
        //        }
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "isRead" : false
        ]
        let value:[String:Any] = [
            "messages":[
                collectionMessage
            ]
        ]
        print("adding Convo: \(conversationID)")
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Sends a message with target conversation and messages
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
    
}










struct DuetUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    // To solve issue that not allow some special symbols("[", "@", "," ...), exchange symbols in email like ".", "@" to "-"
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName : String {
        return "\(safeEmail)_profile_picture.png"
    }
}
