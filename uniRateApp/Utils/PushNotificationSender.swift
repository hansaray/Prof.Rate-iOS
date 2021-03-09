//
//  PushNotificationSender.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 11. 01..
//

import Foundation
import UIKit

class PushNotificationSender {
    func sendPushNotification(to token: String, title: String, body: String, notID: String) {
    let urlString = "https://fcm.googleapis.com/fcm/send"
    let url = NSURL(string: urlString)!
    let paramString: [String : Any] = ["to" : token, "notification" : ["title" : title, "body" : body], "data" : ["notID" : notID]]
    let request = NSMutableURLRequest(url: url as URL)
    request.httpMethod = "POST"
    request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("key=AAAADS2XcdA:APA91bG-esxDqAlfn1qxm-_ge9FfnxYfV0iCsXDxo2CCuftJBaXDqCigAxTmy4ShNZ_ASTooSEy3UQH8Y6m6RBAFiiIWun_H-Ub-0Do6i0Pi3qPizmJLcFG4jsJ_69WALv-z-tJrBxu-", forHTTPHeaderField: "Authorization")
    let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
        do {
            if let jsonData = data {
                if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                    NSLog("Received data:\n\(jsonDataDict))")
                }
            }
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    task.resume()
    }
}
