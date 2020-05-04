//
//  LocalPushManager.swift
//  JokerStrike
//
//  Created by Artyom Lihach on 28/10/2019.
//  Copyright © 2019 JokerStrike. All rights reserved.
//

import UIKit

class LocalPushManager: NSObject {
	static let shared = LocalPushManager()
	
	func schedulePush() {
		if #available(iOS 10.0, *) {
			let content = UNMutableNotificationContent() // Содержимое уведомления
			
			var title = "Text"
			var subtitle = "SubTitle"
			var body = "Body"
			
			content.title = title
			content.subtitle = subtitle
			content.body = body
			content.sound = UNNotificationSound.default
			content.badge = 1
			
			let date = Date(timeIntervalSinceNow: 5)
			let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
			let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
			let identifier = "Local Notification"
			let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
			
			let notificationCenter = UNUserNotificationCenter.current()
			notificationCenter.add(request) { (error) in
				if let error = error {
				}
			}
		}
	}
}
