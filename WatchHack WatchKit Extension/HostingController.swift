//
//  HostingController.swift
//  watchOnlyOntenna WatchKit Extension
//
//  Created by Ryo Iijima on 2020/07/18.
//  Copyright © 2020 ryoiijima. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView> {
    override var body: ContentView {
        return ContentView(sliderData: SliderData.init())
    }
}
