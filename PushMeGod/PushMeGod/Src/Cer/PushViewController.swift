//
//  PushViewController.swift
//  PushMeGod
//
//  Created by ding_qili on 17/1/7.
//  Copyright © 2017年 ding_qili. All rights reserved.
//

import Cocoa

class PushViewController: NSViewController {
    var path:String?
    var pushBridging:PushBridging?
    var hasConnect:Bool = false
    
    @IBOutlet var badge: NSTextField!
    @IBOutlet var pushtitle: NSTextField!
    @IBOutlet var customJson: NSTextView!
    @IBOutlet var debug: NSPopUpButton!
    @IBOutlet var alarmAudio: NSPopUpButton!
    @IBOutlet var deviceToken: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let path = path {
            pushBridging = PushBridging()
            pushBridging?.certificate = path
        }
        customJson.enabledTextCheckingTypes = .allZeros
        customJson.isAutomaticQuoteSubstitutionEnabled = false
        // Do view setup here.
    }
    
    deinit {
        pushBridging?.disconnect()
    }
    @IBAction func push(_ sender: NSButton) {
        if !hasConnect {
            hasConnect = pushBridging?.connect(debug.indexOfSelectedItem == 0) ?? false
            if !hasConnect {
                if let window = self.view.window {
                    let alert  = NSAlert();
                    alert.alertStyle = .warning;
                    alert.messageText = "连接失败，请检查网络或者证书是否正确";
                    alert.beginSheetModal(for: window) { (res) -> Void in
                        
                    };
                }
                return
            }
        }
        guard !deviceToken.stringValue.isEmpty else {
            if let window = self.view.window {
                let alert  = NSAlert();
                alert.alertStyle = .warning;
                alert.messageText = "token isEmpty";
                alert.beginSheetModal(for: window) { (res) -> Void in
                    
                };
            }
            return
        }
        var sound = "default"
        if alarmAudio.indexOfSelectedItem != 0 {
            sound = ""
        }
        let title = pushtitle.stringValue;
        let customJsonS = customJson.string ?? ""
        var payload = "{\"aps\":{\"alert\":\"\(title)\",\"badge\":\(badge.intValue),\"sound\":\"\(sound)\"}}"
        if !customJsonS.isEmpty {
            payload = "{\"aps\":{\"alert\":\"\(title)\",\"badge\":\(badge.intValue),\"sound\":\"\(sound)\"},\(customJsonS)}"
        }
        print(payload)
        let pushResult =  pushBridging?.push(deviceToken.stringValue, payload: payload) ?? false
        if !pushResult {
            if let window = self.view.window {
                let alert  = NSAlert();
                alert.alertStyle = .warning;
                alert.messageText = "推送失败，请检查网络/Token/JSON 是否正确";
                alert.beginSheetModal(for: window) { (res) -> Void in
                    
                };
            }
        }
    }
    
    @IBAction func debugOrNot(_ sender: NSPopUpButton) {
        
    }
    
    @IBAction func noAlarm(_ sender: NSPopUpButton) {
    }
    
    
}
