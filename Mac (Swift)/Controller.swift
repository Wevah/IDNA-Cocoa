//
//  ViewController.swift
//  PunyCocoa Swift
//
//  Created by Nate Weaver on 2020-03-16.
//

import Cocoa

class Controller: NSWindowController {

	@IBOutlet weak var normalField: NSTextField!
	@IBOutlet weak var idnField: NSTextField!

	@IBAction func stringToIDNA(_ sender: NSTextField) {
		self.idnField.stringValue = sender.stringValue.encodedURLString ?? ""
	}

	@IBAction func stringFromIDNA(_ sender: NSTextField) {
		self.normalField.stringValue = sender.stringValue.decodedURLString ?? ""
	}

}
