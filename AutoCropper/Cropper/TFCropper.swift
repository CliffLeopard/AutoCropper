//
//  TFCropper.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/12.
//

import Foundation
import CoreImage
import TensorFlowLite
import opencv2
import SwiftUI

class TFCropper {
    static let modelFileName =  "tensor_quad"
    static let modelFileExtension = "tflite"
    static let desiredSize32:Int32 = 256
    static let desiredSize:Int = 256
    static let desiredChannel = 3
    
    // 裁剪边框检测
    static func detectEdges(cgImg:CGImage) -> SCropRect? {
        if let tensor = tensorPredict(cgImg: cgImg),
           let mat = getTensorMat(tensor: tensor, tensorType: TensorCVType.CV_8UC1) {
            Imgproc.resize(src: mat, dst: mat,
                           dsize: Size2i(width: Int32(cgImg.width) , height: Int32(cgImg.height)))
            return CVCropper.findCropRect(mat: mat)
        }
        return nil
    }
    
    // 裁剪边框绘制
    static func drawCropRect(cgImg: CGImage, cropRect: SCropRect) -> CGImage {
        return CVCropper.drawCropRect(cgImg: cgImg, cropRect: cropRect)
    }
    
    // 图片裁剪
    static func crop(cgImg: CGImage, rect: SCropRect) -> CGImage {
        return CVCropper.crop(cgImg: cgImg, rect: rect)
    }
    
    // 展示TensorFlow的预测结果
    static func showEdges(cgImg: CGImage) -> UIImage? {
        if let tensor = tensorPredict(cgImg: cgImg),
           let mat = getTensorMat(tensor: tensor, tensorType: TensorCVType.CV_8UC3) {
            Imgproc.resize(src: mat, dst: mat,
                           dsize: Size2i(width: Int32(cgImg.width) , height: Int32(cgImg.height)))
            return mat.toUIImage()
        }
        return nil
    }
    
    // 转换TensorFlow 预测结果
    static func getTensorMat(tensor:Tensor, tensorType:TensorCVType) -> Mat? {
        let outMat = Mat(rows: desiredSize32, cols: desiredSize32, type: tensorType.cvType())
        var transformData = tensor.data.withUnsafeBytes { pointer in
            var pixels:[UInt8] = []
            var pixel:[UInt8] = []
            if let pointerFloat = pointer.baseAddress?.bindMemory(to: Float.self, capacity: pointer.count) {
                for x in 0..<desiredSize {
                    for y in 0..<desiredSize {
                        let index = x*desiredSize + y  // 故意反转x,y坐标
                        pixel = tensorType.pixel(tensorValue: pointerFloat[index])
                        do {
                            try outMat.put(row: Int32(x), col: Int32(y), data: pixel)
                            pixels.append(contentsOf: pixel)
                        } catch {
                            debugPrint("build mat error")
                        }
                    }
                }
            }
            pixel = []
            return pixels
        }
        
        if transformData.count != desiredSize * desiredSize * tensorType.getChannel() {
            return nil
        }
        transformData = []
        return outMat
    }
    
    // 获取用于预测的Data
    public static func dataForPredict(cgImg:CGImage) -> Data? {
        let reseizeImg:CGImage = cgImageForPredict(cgImg: cgImg) ?? cgImg
        guard let data = reseizeImg.dataProvider?.data else {
            return nil
        }
        return data as Data
    }
    
    // 获取用于预测的CGImage
    public static func cgImageForPredict(cgImg:CGImage) -> CGImage? {
        let targetMat = Mat()
        let scale:CGFloat = max(CGFloat(cgImg.width), CGFloat(cgImg.height))/CGFloat(desiredSize)
        if(scale > 1.0){
            let originMat = Mat(cgImage: cgImg)
            Imgproc.resize(src: originMat,
                           dst: targetMat,
                           dsize: Size2i(width: desiredSize32 , height: desiredSize32)
            )
            
            Imgproc.cvtColor(src: targetMat, dst: targetMat, code: .COLOR_BGRA2BGR)
            targetMat.convert(to: targetMat, rtype: CvType.CV_32FC3, alpha: 1, beta: 0)
        }
        
        guard targetMat.rows() == desiredSize,
              targetMat.cols() == desiredSize,
              targetMat.type() == CvType.CV_32FC3,
              targetMat.channels() == desiredChannel else {
            return nil
        }
        return targetMat.toCGImage()
    }
    
    // TensorFlow预测
    private static func tensorPredict(cgImg: CGImage) -> Tensor? {
        guard let modelPath = Bundle.main.path(
            forResource: modelFileName,
            ofType: modelFileExtension) else { return nil }
        
        guard let data = dataForPredict(cgImg: cgImg) else {
            return nil
        }

        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
            try interpreter.invoke()
            try interpreter.copy(data, toInputAt: 0)
            try interpreter.invoke()
            let outputSensor = try interpreter.output(at: 0)
            return outputSensor
        } catch {
            print("Tensor Predict error: \(error.localizedDescription)")
        }
        return nil
    }
    
    // 获取CGImage每个像素的颜色。
    private static func readColor(cgImg:CGImage) {
        guard let data = cgImg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            debugPrint("get data failed")
            return
        }
        let bytesPerPixel = cgImg.bitsPerPixel / cgImg.bitsPerComponent
        debugPrint("bitsPerPixel",cgImg.bitsPerPixel, "bitsPerComponent",cgImg.bitsPerComponent, "bytesPerPixel",bytesPerPixel)
        for y in 0..<cgImg.width{
            for x in 0..<cgImg.height{
                let offset = (y * cgImg.bytesPerRow) + (x * bytesPerPixel)
                let components = (r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2])
                debugPrint("components",components)
            }
        }
    }
}

// TensorFlow预测结果的两种使用方式
enum TensorCVType {
    case CV_8UC1   // TensorFlow处理之后的单通道边框图
    case CV_8UC3   // TensorFlow处理之后的三通道完整图
    
    func cvType() -> Int32 {
        switch self {
        case .CV_8UC1:
            return CvType.CV_8UC1
        case .CV_8UC3:
            return CvType.CV_8UC3
        }
    }
    
    func pixel(tensorValue:Float) -> [UInt8] {
        switch self {
        case .CV_8UC1:
            if (tensorValue > -1) {
                return [0xFF]
            } else {
                return [0x00]
            }
            
        case .CV_8UC3:
            if (tensorValue > 0.2) {
                return [0xFF,0xFF,0xFF]
            } else {
                return [0x00,0x00,0x00]
            }
        }
    }
    
    func getChannel() -> Int {
        switch self {
        case .CV_8UC1:
            return 1
        case .CV_8UC3:
            return 3
        }
    }
}
