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

extension DatabaseManager {
    
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                print("cannot get user information set")
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            completion(.success(value))
        }
    }
    
}

// MARK: - Sending messages / conversations

extension DatabaseManager {
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with receiver: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
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
            default:
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationsData:[String:Any] = [
                "id": conversationId,
                "receiver": receiver,
                "name": name,
                "latest_message": [
                    "data": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let receiver_newConversationData:[String:Any] = [
                "id": conversationId,
                "receiver": safeEmail,
                "name": currentName,
                "latest_message": [
                    "data": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // Update recipient conversation entry
            self?.database.child("\(receiver)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    conversations.append(receiver_newConversationData)
                    self?.database.child("\(receiver)/conversations").setValue(conversationId)
                } else {
                    self?.database.child("\(receiver)/conversations").setValue([receiver_newConversationData])
                }
            }
            
            
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
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
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
                    
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                    completion(true)
                }
            }
        }
    }
    
    /// Create schema in database that set root node for conversationID
    private func finishCreatingConversation(name:String, conversationID: String, firstMessage: Message, completion: @escaping (Bool)->Void) {
        
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
            "isRead" : false,
            "name": name
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
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        print("email!!: \(email)")
        database.child("\(email)/conversations").observe(.value) { snapshot in
            print("Conversation View is listening...")
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary -> Conversation? in
                
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let receiver = dictionary["receiver"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["data"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationId, name: name, receiverEmail: receiver, laatestMessage: latestMessageObject)
            }
            
            completion(.success(conversations))
        }

    }
    
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        print("conversationid :: \(id)")
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            
            let messages: [Message] = value.compactMap { dictionary in
                
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["isRead"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
               
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: id,
                               sentDate: date,
                               kind: .text(content))
              
            }
            
            completion(.success(messages))
        }
    }
    
    /// Sends a message with target conversation and messages
    public func sendMessage(to conversationId: String, receiverEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        print(currentEmail)
        
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            default:
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "isRead" : false,
                "name": name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversationId)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                /// note
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { convoSnapshot in
                    guard var latestConversation = snapshot.value as? [[String:Any]] else {
                        print("Cannot find latest Message in \(currentEmail)")
                        completion(false)
                        return
                    }
                    ///
                    let updateValue: [String:Any] = [
                        "data": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    var targetConversation:[String:Any]?
                    var position = 0
                    
                    for conversation in latestConversation {
                        if let currentId = conversation["id"] as? String,
                           currentId == conversationId {
                            targetConversation = conversation
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updateValue
                    
                    print("targetConversation?[latest_message] = \(updateValue)")
                    
                    guard let finalConversation = targetConversation else {
                        print("targetConversation is nil")
                        completion(false)
                        return
                    }
                    latestConversation[position] = finalConversation
                    print("latestConversation[1] : \(latestConversation[position])")
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(latestConversation) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        print("successfully update latestConversation")
                        completion(true)
                    }
                }
                /// note
            }
        }
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
