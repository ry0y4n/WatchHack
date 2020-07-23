// iPhoneからの音声をキャプチャするためのロジックモデルファイル

// ユーザーの携帯電話からのオーディオの'録音'に関連した設定と，サウンドレベルバッファが変更されたときのパブリッシングを扱う
// AVAudioSessionを設定し，0.01秒ごとにサウンドレベルをキャプチャするように設定

import Foundation
import AVFoundation

class MicrophoneMonitor: ObservableObject {
    
    // オーディオレコーダーとオプションのタイマーを設定
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    public var isBackgroundOn: Bool = true
    
    // @Publishedをつけることで変更されるたびにUIも更新される
    @Published public var soundSamples: [Float]
    
    init(numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        // プライバシーのパーミッションが許可されているかどうかを確認
        // ユーザーが拒否した場合fatalErrorを投げる
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
        
        // オーディオ録音が'一時的に保存'される場所のために私たちのURLを作成
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 1,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        // audioRecorderを作成．これで録音できるようになった
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopMonitoring(_:)), name: .didEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.resumeMonitoring(_:)), name: .didEnterForeground, object: nil)
    }
    
    // このオブジェクトが初期化されるとすぐにモニタリングを開始
    private func startMonitoring() {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            
            // updateMeters() を呼び出すことで、オーディオレコーダーの全チャンネルの平均とピークパワー値を更新
            // これによりサウンドチャンネルの平均レベルを取得する
            // またサウンドサンプルを、その時点での audioPower() の値に更新する必要がある
            self.audioRecorder.updateMeters()
            self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        })
    }
    
    public func pauseMonitoring() {
        
        // Stop monitoring for 0.5 seconds
        timer?.invalidate()
        audioRecorder.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.startMonitoring()
        }
        print("pause")
    }
    
    
    @objc public func stopMonitoring(_ notification: Notification) {
        // Check if user wants to monitor in background
        if (self.isBackgroundOn) {
            return
        }
        
        timer?.invalidate()
        audioRecorder.stop()
        print("stopped!!!!")
    }
    
    
    @objc public func resumeMonitoring(_ notification: Notification) {
        print("resume!!!")
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
    
    //　オブジェクトの非初期化
    deinit {
        print("deinitするよ")
        timer?.invalidate()
        audioRecorder.stop()
        print("deinitしたよ")
    }
}
