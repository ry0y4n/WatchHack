//
//  MicrophoneMonitor.swift
//  WatchOntenna
//
//  Created by Ryo Iijima on 2020/07/18.
//  Copyright © 2020 ryoiijima. All rights reserved.
//


import Foundation
import AVFoundation
import WatchConnectivity
import SwiftUI

class MicrophoneMonitor: ObservableObject {
    
    // MARK: - Set up audio recorder and an optional timer
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    public var isBackgroundOn: Bool = true
    
    // MARK: - Mark soundSamples an @Published to publish new information everytime it changes
    @Published public var soundSamples: [Float]
    
    init(numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        // Set up an audio session and check if the privacy permission has been granted.
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
        
        // Create URL where audio recording will be stored temporarily.
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 1,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        // Create audioRecorder with our URL.
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        // Set up notification center observer.
        // .didEnterBackground and .didEnterForeground are defined in ExtensionDelegate.swift.
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopMonitoring(_:)), name: .didEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.resumeMonitoring(_:)), name: .didEnterForeground, object: nil)
    }
    
    // MARK: - Start monitoring as soon as this object is initialized.
    private func startMonitoring() {
        
        // NOTE:
        // Make sure to set audioRecorder.isMeteringEnabled true.
        // By default, audio level metering is off for an audio recorder.
        // Because metering uses computing resources, turn it on only if you intend to use it.
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            
            // Refresh the average and peak power values for all channels of an audio recorder.
            // This allows us to get the average power for our sound channel.
            self.audioRecorder.updateMeters()
            self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        })
    }
    
    
    public func pauseMonitoring() {
        
        // Stop monitoring for 0.5 seconds
        timer?.invalidate()
        audioRecorder.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startMonitoring()
        }
    }
    
    
    @objc public func stopMonitoring(_ notification: Notification) {
        
        // Check if user wants to monitor in background
        if (self.isBackgroundOn) {
            return
        }
        
        timer?.invalidate()
        audioRecorder.stop()
    }
    
    
    @objc public func resumeMonitoring(_ notification: Notification) {
        startMonitoring()
    }
    
    public func halt() {
        print("resetするよ")
        timer?.invalidate()
        audioRecorder.stop()
        print("resetしたよ")
    }
    
    public func restart() {
        print("restartするよ")
        startMonitoring()
        print("restartしたよ")
    }
}

