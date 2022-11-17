//
//  DataModel.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import AVFoundation
import SwiftUI

final class CameraDataModel: ObservableObject {
    static var sizeRate:CGFloat {
        let bounds = UIScreen.main.bounds
        if bounds.height / bounds.width >= 1.8 {
            return 4/3
        } else {
            return 1.0
        }
    }
    static var scaleWidth = UIScreen.main.bounds.width
    static var scaleHeight = scaleWidth * sizeRate
    let camera = Camera()
    
    @Published var showLoading = false
    @Published var photoModel:PhotoDataModel = PhotoDataModel()
    @Published var photoData:PhotoData? = nil
    @Published var showCapture:Bool = false
    @Published var previewImage: Image?             // 预览Image
    @Published var cropRect:SCropRect?            // 裁剪区域
    @Published var showPixelSelector = false    // 分辨率选择
    @Published var showCrop = true             // 自动裁剪
    @Published var showHelpLine = true        // 辅助线
    @Published var showFlash = false {       // 闪光灯
        didSet {
            self.camera.changeFlashMode(mode: showFlash ? AVCaptureDevice.FlashMode.on : AVCaptureDevice.FlashMode.off  )
        }
    }
    
    init() {
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleCameraPhotos()
        }
    }
    
    // 不断拉取预览图片
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map {
                let ciImg = CIImage(cvPixelBuffer: $0).cropByRate(sizeRate: CameraDataModel.sizeRate)
                self.detectCrop(ciImage: ciImg)
                return ciImg.image
            }
        for await image in imageStream {
            Task { @MainActor in
                previewImage = image
            }
        }
    }
    
    private var detecting = false
    let screenWidth = UIScreen.main.bounds.width
    
    // 裁剪轮廓检测
    func detectCrop(ciImage:CIImage) {
        if !self.detecting  && self.showCrop {
            if let cgImg = ciImage.asCgImage {
                self.detecting = true
                DispatchQueue.global().async {
                    let rect = LensCropper.detectEdges(cgImg:cgImg)
                    DispatchQueue.main.async {
                        if let notNilRect = rect {
                            let rate = self.screenWidth / ciImage.extent.size.width
                            self.cropRect = notNilRect.scale(degree: rate)
                        } else {
                            self.cropRect = SCropRect(width: self.screenWidth, heiht: self.screenWidth * CameraDataModel.sizeRate)
                        }
                        self.detecting = false
                    }
                }
            }
        }
    }
    
    // 不断拉取拍照图片
    func handleCameraPhotos() async {
        let unpackedPhotoStream = camera.photoStream
            .compactMap { await self.unpackPhoto($0) }
        
        for await photoData in unpackedPhotoStream {
            Task { @MainActor in
                self.photoData = photoData
                self.photoModel.thumbnailImage = photoData.thumbnailImage
                self.camera.isPreviewPaused = false
                self.showLoading = false
                self.showCapture = true
            }
        }
    }
    
    
    // 拍照
    func takePhoto() {
        self.showLoading = true
        self.camera.isPreviewPaused = true
        self.camera.takePhoto()
    }
    
    // 拍照图片解码
    private func unpackPhoto(_ photo: AVCapturePhoto) async -> PhotoData? {
        guard let imageData = photo.fileDataRepresentation() else { return nil }
        guard let previewCGImage = photo.previewCGImageRepresentation(),
              let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
              let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation) else { return nil }
        
        // 缩略图
        let previewDimensions = photo.resolvedSettings.previewDimensions
        let thumbnailSize = (width: Int(previewDimensions.width), height: Int(previewDimensions.height))
        
        // 拍到的原始图像
        let imageOrientation = Image.Orientation(cgImageOrientation)
        let thumbnailImage = Image(decorative: previewCGImage, scale: 1, orientation: imageOrientation)
        let photoDimensions = photo.resolvedSettings.photoDimensions
        let imageSize = (width: Int(photoDimensions.width), height: Int(photoDimensions.height))
        debugPrint("imageSize",imageSize)
        
        // 将拍摄的图片裁剪到预览比例
        guard let cIImg = CIImage(data: imageData,options: [.applyOrientationProperty: true]) else {return nil}
        let cropedImg = cIImg.cropByRateAndOrientation(sizeRate: CameraDataModel.sizeRate, orientation: cgImageOrientation)
        guard let cropedData = cropedImg.png else { return nil }
        let cropedSize = (width: Int(cropedImg.extent.width), height: Int(cropedImg.extent.height))
        
        return PhotoData(thumbnailImage: thumbnailImage,
                         thumbnailSize: thumbnailSize,
                         imageData: cropedData,
                         captureImg:cropedImg,
                         imageSize: cropedSize,
                         orientation: cgImageOrientation)
    }
}

// 照片数据结构
struct PhotoData {
    var thumbnailImage: Image
    var thumbnailSize: (width: Int, height: Int)
    var imageData: Data
    var captureImg:CIImage
    var imageSize: (width: Int, height: Int)
    var orientation:CGImagePropertyOrientation
}

// 照片方向调整
fileprivate extension Image.Orientation {
    
    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

enum PhotoPreset: String {
    case SUPER =  "超清"
    case HEIGHT = "高清"
    case BIG =    "大图"
    case NOTMAL = "标准"
    case SMALL =  "小图"
    
    func getPreset() -> AVCaptureSession.Preset {
        switch self {
        case .SUPER:
            return .photo
        case .HEIGHT:
            return .high
        case .BIG:
            return .medium
        case .NOTMAL:
            return .low
        case .SMALL:
            return .vga640x480
        }
    }
    
    static func getList() -> [PhotoPreset] {
        return [.SUPER,.HEIGHT,.BIG,.NOTMAL,.SMALL]
    }
}
