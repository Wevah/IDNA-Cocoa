//
//  AppDelegate.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-03-16.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		guard UTS46.characterMap.isEmpty else { return }
		if let blobURL = Bundle.main.url(forResource: "uts46", withExtension: "xz") {
			do {
				try UTS46.load(from: blobURL, compression: .lzma)
			} catch {
				print("error: \(error)")
			}
		}

	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

