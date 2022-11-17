//
//  EnvironmentValues+.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import Foundation
import SwiftUI
extension EnvironmentValues {
    var dismiss: () -> Void {
        { presentationMode.wrappedValue.dismiss() }
    }
}
