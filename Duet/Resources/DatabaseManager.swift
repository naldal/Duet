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

}

// MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void))  {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        // To check email is exist, find safeEmail in firebase database, and then check nil for snapshot.
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            // if snapshot is not nil, then completion closure argument will be allocated "false"
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            // completion closure argument will be allocated "true"
            completion(true)
        }
    }
    
    /// Insert new user to database
    public func insertUser(with user: DuetUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
}

struct DuetUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    // To solve issue that not allow some special symbols("[", "@", "," ...), exchange symbols in email like ".", "@" to "-"
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
//    let profilePictureUrl : String
}
