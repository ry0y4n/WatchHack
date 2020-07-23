//
//  ContentView.swift
//  SoundVisualizer
//
//  Created by momosuke on 2020/07/15.
//  Copyright © 2020 momosuke. All rights reserved.
//

import SwiftUI
import CoreHaptics
import Combine


let numberOfSamples: Int = 10

struct ContentView: View {
    @State public var engine: CHHapticEngine?
    @State public var sliderValue: Double = 50
    @State private var showingModal = false
    // マイクロホンモニターのobservedObjectを作成
    @ObservedObject private var mic = MicrophoneMonitor(numberOfSamples: numberOfSamples)

    // 生のサウンドレベル（マイクモニターから使用するために与えられたレベル）を取り込むヘルパー関数を作成
    // -160 ~ 0の入力を0.1 ~ 25の間に正則化し，可視化の都合で300までにさらに変換
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2
        if(CGFloat(level * (300 / 25)) > CGFloat(sliderValue * 4)) {
            print(">200: 何か喋ってる")
            //mic.pauseMonitoring()
            playHaptics()
        }
        return CGFloat(level * (300 / 25))
        
//        let cutoffLevel: Double = 10.0
//        var level = max(cutoffLevel, Double(CGFloat(level) + 160)) - cutoffLevel
//        level = level * 100 / (160 - cutoffLevel)
//
//        if(level > sliderValue) {
//            //mic.pauseMonitoring()
//            playHaptics()
//        }
//        return CGFloat(level)
    }
    
    @State private var value = 0

    var body: some View {
        VStack {
            // 正規化されたバーを表示
            HStack(spacing: 4) {
                ForEach(mic.soundSamples, id: \.self) { level in
                    BarView(value: self.normalizeSoundLevel(level: level))
                }
            }
            .padding(.top, 200)
            Spacer()
            Button(action: {
                self.showingModal.toggle()
            }) {
                Text("Threshold Value")
            }.sheet(isPresented: $showingModal) {
                ModalView()
            }
            Text("\(Int(sliderValue))")
                .fontWeight(.regular)
                .font(.system(size: 70))
                .onAppear(perform: prepareHaptics)
                .onTapGesture(perform: playHaptics)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    print("prepare!!!")
                    self.prepareHaptics()
                    
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { (_ ) in
                    print("will resign")
                    self.engine?.stop(completionHandler: { (err) in
                        print("stopped")
                    })
                }
//            Toggle("Background", isOn: $mic.isBackgroundOn)
//            .padding(.vertical)
            Slider(value: $sliderValue, in: 1...100)
                .padding()
        }
    }

    func prepareHaptics() {
        // 接続デバイスで触覚フィードバックをサポートしているかチェック
        guard  CHHapticEngine.capabilitiesForHardware()
            .supportsHaptics else { print("no support"); return; }
        do {
            // 触覚フィードバックスタート
            self.engine = try! CHHapticEngine()
            try engine!.start(completionHandler: { (_ ) in
                print("準備完了")
            })
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription).")
        }
    }

    func playHaptics() {
        mic.halt()
        print("触覚フィードバックスタート")
        guard CHHapticEngine.capabilitiesForHardware()
            .supportsHaptics  else { print("no support"); return; }

        let audioEvent = CHHapticEvent(eventType: .audioContinuous, parameters: [
            CHHapticEventParameter(parameterID: .audioPitch, value: 0.7),
            CHHapticEventParameter(parameterID: .audioVolume, value: 1),
            CHHapticEventParameter(parameterID: .decayTime, value: 0.3),
            CHHapticEventParameter(parameterID: .sustained, value: 0)
        ], relativeTime: 0)
        let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1),
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        ], relativeTime: 0)

        do {
            let pattern = try! CHHapticPattern(events: [audioEvent, hapticEvent], parameters: [])
            //let pattern = try CHHapticPattern(events: events, parameters: []) // CHHapticPattern: イベントを束ねるオブジェクト
            let player = try engine?.makePlayer(with: pattern) // makePlayer: パターンからプレイヤーをsakusei
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
        mic.restart()
        print("フィードバック終了")

    }
}

struct BarView: View {

    // サウンドレベルを UI が認識できるものに変換
    var value: CGFloat
    
    var body: some View {
        ZStack {
            // ラウンドとった長方形で可視化
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .top, endPoint: .bottom))
            
                .frame(width: (UIScreen.main.bounds.width - CGFloat(numberOfSamples) * 4) / CGFloat(numberOfSamples), height: value)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ModalView: View {
    var body: some View {
        Text("Modal View.")
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView()
    }
}
