//
//  ContentView.swift
//  watchOnlyOntenna WatchKit Extension
//
//  Created by Ryo Iijima on 2020/07/18.
//  Copyright © 2020 ryoiijima. All rights reserved.
//

import SwiftUI
import Combine

let numberOfSamples: Int = 10

class SliderData: ObservableObject {
    let didChange = PassthroughSubject<SliderData,Never>()

    @Published var sliderValue: Double = 50 {
        didSet {
//            print("sliderValue \(sliderValue)")
            didChange.send(self)
        }
    }
}


struct ContentView: View {
    // ObservedObject of slider data representing a threshold value.
    @ObservedObject var sliderData:SliderData
    
    // Create ObservedObject of a microphone monitor passing in 10 samples.
    @ObservedObject private var mic = MicrophoneMonitor(numberOfSamples: numberOfSamples)
    
    // cutoffLevel must be within the range of [0-160]
    var cutoffLevel: Float = 130.0
    
    
    
    // Raw sound level from MicrophoneMonitor is between -160dB and 0dB.
    // Cut off below cutoffLevel and map it to the range of [0-100]dB
    private func db(level: Float) -> Float {
        var level = max(cutoffLevel, level + 160) - cutoffLevel
        level = level * 100 / (160 - cutoffLevel)
        
        if(level > Float(sliderData.sliderValue)) {
            mic.pauseMonitoring()
            WKInterfaceDevice.current().play(.directionUp)
        }
        return level
    }
    
    var body: some View {
        ZStack {
            // Each parameters of Color must be within [0-1].
            Rectangle()
                .fill(Color(
                    red: Double(db(level: mic.soundSamples[0]) / 100),
                    green: Double(db(level: mic.soundSamples[0]) / 100),
                    blue: Double(db(level: mic.soundSamples[0]) / 100)
                    )
            )
            VStack {
                Text("閾値: " + String(sliderData.sliderValue).prefix(4) + " %")
                    .padding(.top, 6.0)
                
                Slider(value: $sliderData.sliderValue,in: 0...100)
                    .padding(.top, -10.0)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Toggle("Background", isOn: $mic.isBackgroundOn)
                        .padding(.vertical)
                    
                    Spacer()
                }
                
            }
            
        }
    }
    

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(sliderData: SliderData.init())
    }
}
