//
//  ICropperBaseImpl.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/12.
//

import Foundation
import CoreImage

class CICropper {
    // 计算裁剪区域
    static func detectEdges(cgImg: CGImage) -> SCropRect? {
        let ciContext = CIContext(options: nil)
        var rect:SCropRect? = nil
        if let detector = CIDetector(ofType: CIDetectorTypeRectangle,context: ciContext, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) {
            let ciRect = detector.features(in: CIImage(cgImage: cgImg)).first as? CIRectangleFeature
            if ciRect == nil {
                rect = nil
            } else {
                rect = SCropRect(cirf: ciRect!)
            }
        }
        return rect
    }
    
    // 绘制裁剪区域边框
    static func drawCropRect(cgImg: CGImage, cropRect: SCropRect) -> CGImage {
        let ciImage = drawRectToImage(ciIamge: CIImage(cgImage: cgImg), SCropRect: cropRect)
        return ciImage.asCgImage!
    }
    
    // 裁剪
    static func crop(cgImg: CGImage, rect: SCropRect) -> CGImage {
        let image = CIImage(cgImage: cgImg)
        let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection")!
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.topLeft),
                                       forKey: "inputTopLeft")
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.topRight),
                                       forKey: "inputTopRight")
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.bottomRight),
                                       forKey: "inputBottomRight")
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.bottomLeft),
                                       forKey: "inputBottomLeft")
        perspectiveCorrection.setValue(image,
                                       forKey: kCIInputImageKey)
        let outImage = perspectiveCorrection.outputImage
        
        if let outCGImage = outImage?.asCgImage {
            return outCGImage
        } else {
            return cgImg
        }
    }
    
    // 使用滤镜方式绘制CropRect
    private static func drawRectToImage(ciIamge:CIImage,SCropRect:SCropRect) -> CIImage {
        let blackColor = CIColor(red: 0, green: 0, blue: 0,alpha: 1.0)
        let topLine = SCropRect.topLineRect(10)
        let leftLine = SCropRect.leftLineRect(10)
        let bottomLine = SCropRect.bottomLineRect(10)
        let rightLine = SCropRect.rightLineRect(10)
        
        var filterImage = addLineFilter(ciImage: ciIamge, lineRect: topLine, color: blackColor)
        filterImage = addLineFilter(ciImage: filterImage, lineRect: leftLine, color: blackColor)
        filterImage = addLineFilter(ciImage: filterImage, lineRect: bottomLine, color: blackColor)
        filterImage = addLineFilter(ciImage: filterImage, lineRect: rightLine, color: blackColor)
        
        return filterImage
    }
    
    
    // 使用添加滤镜的方式在原画上画线
    private static func addLineFilter(ciImage:CIImage, lineRect:SCropRect, color:CIColor) -> CIImage {
        var overlay = CIImage(color: color)
        overlay = overlay.cropped(to: ciImage.extent)
        overlay = overlay.applyingFilter(
            "CIPerspectiveTransformWithExtent",
            parameters:[kCIInputExtentKey : CIVector(cgRect: ciImage.extent),
                        "inputTopLeft": CIVector(cgPoint:lineRect.topLeft),
                        "inputTopRight": CIVector(cgPoint:lineRect.topRight),
                        "inputBottomRight": CIVector(cgPoint:lineRect.bottomRight),
                        "inputBottomLeft": CIVector(cgPoint:lineRect.bottomLeft)])
        return overlay.composited(over: ciImage)
    }
}

