//
//  CoreMLCropper.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/17.
//

import CoreML
import Foundation
import SwiftUI
import opencv2

class CoreMLCropper {
    private static let modelFileName = "coreml_quad"
    private static let modelFileExtension = "mlmodelc"
    static let desiredSize32:Int32 = 256
    static let desiredSize:Int = 256
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
    
    // 获取用于预测的CGImage
    public static func cgImageForML(cgImg:CGImage) -> CGImage? {
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
    
    static func predict(cgImage:CGImage) -> Image?{
        guard let model = CoreMLCropper.model else {
            debugPrint("load model fail")
            return nil
        }
        let description = model.modelDescription
        let dict = description.inputDescriptionsByName
        let featureNames = dict.keys
        debugPrint("featureNames",featureNames)
        var constraint: MLImageConstraint {
            let description = model.modelDescription
            let imageInputDescription = description.inputDescriptionsByName["image"]!
            let imageConstraint = imageInputDescription.imageConstraint!
            return imageConstraint
        }
        
        do{
            let outProvider = try model.prediction(from: InputImpl(cgImage: cgImage, constraint: constraint))
            let featureValue = outProvider.featureValue(for: "image_output")
            if let buffer = featureValue?.imageBufferValue {
                let ciImage = CIImage(cvPixelBuffer: buffer)
                if let cgImage = ciImage.asCgImage {
                    let cropper = CICropper.detectEdges(cgImg: cgImage)
                    return Image(uiImage: UIImage(cgImage: cgImage))
                }
            }
        } catch{
            debugPrint("predict fail", error.localizedDescription)
        }
        return nil
    }
}
