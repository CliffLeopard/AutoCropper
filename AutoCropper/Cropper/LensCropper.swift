//
//  LensCropper.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/17.
//

import Foundation
import SwiftUI
import CoreML
import opencv2

class LensCropper {
    private static let modelFileName = "coreml_quad"
    private static let modelFileExtension = "mlmodelc"
    static let desiredSize32:Int32 = 256
    static let desiredSize:Int = 256
    
    // 模型加载
    static var model:MLModel? {
        guard let modelPath = Bundle.main.path(
            forResource: modelFileName,
            ofType: modelFileExtension) else {
            debugPrint("model not exit")
            return nil
        }
        let compile_url = URL(fileURLWithPath: modelPath)
        let config = MLModelConfiguration()
        do {
            let model =  try MLModel(contentsOf: compile_url,configuration: config)
            return model
        } catch {
            debugPrint("error",error.localizedDescription)
        }
        return nil
    }
    
    // 模型约束
    static var constraint: MLImageConstraint? {
        if let mlModel = model {
            let description = mlModel.modelDescription
            let imageInputDescription = description.inputDescriptionsByName["image"]!
            let imageConstraint = imageInputDescription.imageConstraint!
            return imageConstraint
        }
        return nil
    }
    
    // 边界预测
    static func detectEdges(cgImg: CGImage) -> SCropRect? {
        let zero:UInt8 = 0x00
        let one:UInt8 = 0xFF
        
        guard let cgImage = lensPredict(cgImage: cgImg) else {
            return nil
        }
        let mat = Mat(cgImage: cgImage)
        let outMat = Mat(rows: desiredSize32, cols: desiredSize32, type: CvType.CV_8UC1)
        for i in 0..<desiredSize32 {
            for j in 0..<desiredSize32 {
                let point = mat.get(row: i, col: j)
                do {
                    if point[0] == 0.0 && point[1] == 0.0 && point[2] == 0.0{
                        try outMat.put(row: i, col: j, data: [zero])
                    } else {
                        try outMat.put(row: i, col: j, data: [one])
                    }
                } catch {
                    debugPrint("put error", error.localizedDescription)
                }
            }
        }
        
        Imgproc.resize(src: outMat, dst: outMat,
                       dsize: Size2i(width: Int32(cgImg.width) , height: Int32(cgImg.height)))
        
        let cropRect = CVCropper.findCropRect(mat: outMat)
        return cropRect
    }
    
    // 显示边界图
    static func showEdges(cgImg: CGImage) -> UIImage? {
        if let mat = predictedMat(cgImg: cgImg) {
            return mat.toUIImage()
        }
        return nil
    }
    
    // 获取预测恢复之后的Image
    private static func predictedMat(cgImg:CGImage) -> Mat? {
        guard let cgImage = lensPredict(cgImage: cgImg) else {
            return nil
        }
        let mat = Mat(cgImage: cgImage)
        Imgproc.resize(src: mat, dst: mat,
                       dsize: Size2i(width: Int32(cgImg.width) , height: Int32(cgImg.height)))
        return mat
    }
    
    // 通过Lens模型预测获得结果
    static func lensPredict(cgImage:CGImage) -> CGImage? {
        guard let cgImage = cgImageForML(cgImg: cgImage),
              let model = LensCropper.model,
              let constraint = LensCropper.constraint else {
            return nil
        }
        do {
            let outProvider = try model.prediction(from: InputImpl(cgImage: cgImage, constraint: constraint))
            let featureValue = outProvider.featureValue(for: "image_output")
            if let buffer = featureValue?.imageBufferValue {
                return CIImage(cvPixelBuffer: buffer).asCgImage
            }
        } catch{
            debugPrint("predict fail", error.localizedDescription)
        }
        return nil
    }
    
    // 获取用于预测的CGImage: 256*256
    private static func cgImageForML(cgImg:CGImage) -> CGImage? {
        let targetMat = Mat()
        let scale:CGFloat = max(CGFloat(cgImg.width), CGFloat(cgImg.height))/CGFloat(desiredSize)
        if(scale > 1.0){
            let originMat = Mat(cgImage: cgImg)
            Imgproc.resize(src: originMat,
                           dst: targetMat,
                           dsize: Size2i(width: desiredSize32 , height: desiredSize32)
            )
        }
        return targetMat.toCGImage()
    }
}
