//
//  PermissionCenter.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import Foundation
import Photos

struct PermissionCenter {
    static func checkAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            return true
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        case .denied:
            return false
        case .limited:
            return false
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
