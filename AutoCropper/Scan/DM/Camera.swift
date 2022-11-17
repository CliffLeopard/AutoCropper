//
//  Camera.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//
//  相机工具类，用来获取预览视频流和拍摄照片
//

import AVFoundation
import CoreImage
import CoreMotion
import UIKit


class Camera: NSObject {
    private let captureSession = AVCaptureSession()
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var motion:CMMotionManager = CMMotionManager()
    private var flashMode:AVCaptureDevice.FlashMode = .off
    private var sessionQueue: DispatchQueue!
    private var currentZoomFactor:CGFloat = 1.0
    var isPreviewPaused = false
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    // 相机Device
    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice = captureDevice else { return }
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }
    
    // 预览流 和 拍摄的照片流
    private var addToPhotoStream: ((AVCapturePhoto) -> Void)?
    private var addToPreviewStream: ((CVImageBuffer) -> Void)?
    
    lazy var previewStream: AsyncStream<CVImageBuffer> = {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                if !self.isPreviewPaused {
                    continuation.yield(ciImage)
                }
            }
        }
    }()
    
    lazy var photoStream: AsyncStream<AVCapturePhoto> = {
        AsyncStream { continuation in
            addToPhotoStream = { photo in
                continuation.yield(photo)
            }
        }
    }()
    
    // 初始化
    override init() {
        super.init()
        initialize()
    }
    
    private func initialize() {
        sessionQueue = DispatchQueue(label: "session queue")
        captureDevice = availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
        
        // 处理非锁定的屏幕方向问题
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(updateForDeviceOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    
    // 开始预览
    func start() async {
        let authorized = await checkAuthorization()
        guard authorized else {
            debugPrint("Camera access was not authorized.")
            return
        }
        
        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return
        }
        startGyros()
        sessionQueue.async { [self] in
            self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
    }
    
    // 停止预览
    func stop() {
        guard isCaptureSessionConfigured else { return }
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
        stopGyros()
    }
    
    // 拍照
    func takePhoto() {
        guard let photoOutput = self.photoOutput else { return }
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            let isFlashAvailable = self.deviceInput?.device.isFlashAvailable ?? false
            photoSettings.flashMode = isFlashAvailable ? self.flashMode : .off
            photoSettings.isHighResolutionPhotoEnabled = true
            
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            photoSettings.photoQualityPrioritization = .balanced
            
            if let photoOutputVideoConnection = photoOutput.connection(with: .video) {
                // 陀螺仪判断方向，自动纠正拍照
                if photoOutputVideoConnection.isVideoOrientationSupported {
                    var gyrosOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
                    if let motion = self.motion.deviceMotion {
                        let x = motion.gravity.x
                        let y = motion.gravity.y
                        if fabs(y) >= fabs(x) {
                            if y >= 0 {
                                gyrosOrientation = .portraitUpsideDown
                            } else {
                                gyrosOrientation = .portrait
                            }
                        } else {
                            if x >= 0 {
                                gyrosOrientation = .landscapeLeft
                            } else {
                                gyrosOrientation = .landscapeRight
                            }
                        }
                    }
                    photoOutputVideoConnection.videoOrientation = gyrosOrientation
                }
            }
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // 改变分辨率
    func changePixel(preset:AVCaptureSession.Preset) {
        self.captureSession.beginConfiguration()
        captureSession.sessionPreset = preset
        self.captureSession.commitConfiguration()
        debugPrint("captureSessionChanged",preset)
    }
    
    // 改变闪光灯
    func changeFlashMode(mode:AVCaptureDevice.FlashMode) {
        self.flashMode = mode
    }
    
    
    // 聚焦到某个点
    func focusOnPosition(position:CGPoint) {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let focusPoint = CGPoint(x: position.x/width, y: position.y/height)
        debugPrint("focusOnPosition",focusPoint)
        Task {
            if let device = captureDevice {
                do {
                    try device.lockForConfiguration()
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusPointOfInterest = focusPoint
                        device.focusMode = .continuousAutoFocus
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposurePointOfInterest = focusPoint
                        device.exposureMode = .continuousAutoExposure
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = false
                    device.unlockForConfiguration()
                    
                } catch {
                    debugPrint("Unexpected error: \(error).")
                }
            }
        }
    }
    
    // 景深调整
    func zoom(lenght:CGFloat) {
        let radio = lenght/UIScreen.main.bounds.height
        let nowZoomFactor = max(1,currentZoomFactor * (1+radio))
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = nowZoomFactor
                device.unlockForConfiguration()
            } catch {
                debugPrint("zoom faild")
            }
        }
    }
    
    // 景深调整结束
    func zoomEnd(lenght:CGFloat) {
        let radio = lenght/UIScreen.main.bounds.height
        currentZoomFactor = max(1,currentZoomFactor * (1+radio))
    }
    
    private func getMaxZoomFactor() -> CGFloat {
        guard let device = captureDevice else {
            return 1
        }
        if #available(iOS 11.0, *) {
            return device.maxAvailableVideoZoomFactor / 2
        } else {
            return device.activeFormat.videoMaxZoomFactor / 2
        }
    }
    
    // 反转摄像头
    func switchCaptureDevice() {
        if let captureDevice = captureDevice, let index = availableCaptureDevices.firstIndex(of: captureDevice) {
            let nextIndex = (index + 1) % availableCaptureDevices.count
            self.captureDevice = availableCaptureDevices[nextIndex]
        } else {
            self.captureDevice = AVCaptureDevice.default(for: .video)
        }
    }
    
    // 相机 相关配置
    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        var success = false
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }
        
        guard
            let captureDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            debugPrint("Failed to obtain video input.")
            return
        }
        
        let photoOutput = AVCapturePhotoOutput()
        
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
        
        
        guard captureSession.canAddInput(deviceInput) else {
            debugPrint("Unable to add device input to capture session.")
            return
        }
        guard captureSession.canAddOutput(photoOutput) else {
            debugPrint("Unable to add photo output to capture session.")
            return
        }
        guard captureSession.canAddOutput(videoOutput) else {
            debugPrint("Unable to add video output to capture session.")
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        
        self.deviceInput = deviceInput
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
        
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        updateVideoOutputConnection()
        
        isCaptureSessionConfigured = true
        
        success = true
    }
    
    // 权限检测
    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        case .denied:
            return false
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // 对应特定设备更新 captureSession
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // 删除Session链接的所有 deviceInput
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        // 获取当前Device的 deviceInput并配置到captureSessio中
        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }
        updateVideoOutputConnection()
    }
    
    // 获取CaptureDevice的DeviceInput
    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            debugPrint("Error getting capture device input: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 更新视频预览链接
    private func updateVideoOutputConnection() {
        if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video) {
            if videoOutputConnection.isVideoMirroringSupported {
                videoOutputConnection.isVideoMirrored = isUsingFrontCaptureDevice
            }
        }
    }
    
    // 设备方向
    private var deviceOrientation: UIDeviceOrientation {
        var orientation = UIDevice.current.orientation
        if orientation == UIDeviceOrientation.unknown {
            orientation = UIScreen.main.orientation
        }
        return orientation
    }
    
    @objc
    func updateForDeviceOrientation() {
        
    }
    
    private func videoOrientationFor(_ deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch deviceOrientation {
        case .portrait: return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft: return AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight: return AVCaptureVideoOrientation.landscapeLeft
        default: return nil
        }
    }
    
    
}

// 获取相机设备相关
extension Camera {
    var isUsingFrontCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return frontCaptureDevices.contains(captureDevice)
    }
    
    var isUsingBackCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return backCaptureDevices.contains(captureDevice)
    }
    
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera, .builtInDualWideCamera], mediaType: .video, position: .unspecified).devices
    }
    
    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .front }
    }
    
    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .back }
    }
    
    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
#if os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        devices += allCaptureDevices
#else
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
#endif
        return devices
    }
    
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter( { $0.isConnected } )
            .filter( { !$0.isSuspended } )
    }
}



// 代理拍照
extension Camera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            debugPrint("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        addToPhotoStream?(photo)
    }
}

// 代理预览
extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        if connection.isVideoOrientationSupported,
           let videoOrientation = videoOrientationFor(deviceOrientation) {
            connection.videoOrientation = videoOrientation
        }
        
        addToPreviewStream?(pixelBuffer)
    }
}

// 陀螺仪传感器
extension Camera {
    func startGyros() {
        if motion.isGyroAvailable {
            self.motion.gyroUpdateInterval = 60.0 / 60.0
            self.motion.startAccelerometerUpdates()
            self.motion.startGyroUpdates()
            self.motion.startMagnetometerUpdates()
            self.motion.startDeviceMotionUpdates()
        }
    }
    func stopGyros() {
        self.motion.stopGyroUpdates()
    }
}

// 屏幕方向
fileprivate extension UIScreen {
    var orientation: UIDeviceOrientation {
        let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
        if point == CGPoint.zero {
            return .portrait
        } else if point.x != 0 && point.y != 0 {
            return .portraitUpsideDown
        } else if point.x == 0 && point.y != 0 {
            return .landscapeRight //.landscapeLeft
        } else if point.x != 0 && point.y == 0 {
            return .landscapeLeft //.landscapeRight
        } else {
            return .unknown
        }
    }
}
