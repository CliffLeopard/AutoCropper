////
////  MLCropper.swift
////  AutoCropper
////
////  Created by CliffLeopard on 2022/10/13.
////  使用CoreML 代理加速时，模型和数据 维度 总是不匹配，暂时不使用
////
//
//import Foundation
//import CoreImage
//import TensorFlowLite
//import opencv2
//
//class MLCropper  {
//    public static func detectEdges(cgImg: CGImage) -> SCropRect? {
//        if let tensor = tensorPredict(cgImg: cgImg),
//           let mat = TFCropper.getTensorMat(tensor: tensor, tensorType: TensorCVType.CV_8UC1) {
//            Imgproc.resize(src: mat, dst: mat,
//                           dsize: Size2i(width: Int32(cgImg.width) , height: Int32(cgImg.height)))
//            if let cropRect = CVCropper.findCropRect(mat: mat) {
//                return cropRect
//            }
//        }
//        return nil
//    }
//
//    public static func tensorPredict(cgImg: CGImage) -> Tensor? {
//        var options = CoreMLDelegate.Options()
//        options.enabledDevices = .all
//        var delegate:Delegate? = CoreMLDelegate(options:options)
//        if delegate == nil {
//            delegate = MetalDelegate()  // Add Metal delegate options if necessary.
//        }
//
//        if let delegate = delegate {
//            do {
//                let modelPath = Bundle.main.path(
//                    forResource: "hed_lite_model_quantize",
//                    ofType: "tflite"
//                )
//                var options = Interpreter.Options()
//                options.isXNNPackEnabled = false
//                let interpreter = try Interpreter(modelPath: modelPath!,delegates: [delegate])
//                let inputShape = try interpreter.input(at: 0).shape
//                debugPrint("inputShape",inputShape)
//                if let data = TFCropper.dataForPredict(cgImg: cgImg) {
//                    try interpreter.copy(data, toInputAt: 0)
//                    try interpreter.invoke()
//                    let outputSensor = try interpreter.output(at: 0)
//                    return outputSensor
//                }
//            } catch {
//                debugPrint("Unexpected error: \(error).")
//            }
//        }
//        return nil
//    }
//
//    // 裁剪边框绘制
//    static func drawCropRect(cgImg: CGImage, cropRect: SCropRect) -> CGImage {
//        return CVCropper.drawCropRect(cgImg: cgImg, cropRect: cropRect)
//    }
//
//    // 图片裁剪
//    static func crop(cgImg: CGImage, rect: SCropRect) -> CGImage {
//        return CVCropper.crop(cgImg: cgImg, rect: rect)
//    }
//
//}
