//
//  ICropper.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/12.
//

import Foundation
import CoreImage
import opencv2

protocol ICropper {
    func detectEdges(cgImg:CGImage) -> SCropRect?
    func drawCropRect(cgImg: CGImage, cropRect: SCropRect) -> CGImage
    func crop(cgImg:CGImage, rect:SCropRect) -> CGImage
}

extension ICropper {
    // 检测并绘制边框
    func detectAndDrawEdges(cgImg:CGImage) -> CGImage {
        if let rect = self.detectEdges(cgImg: cgImg){
            return drawCropRect(cgImg: cgImg, cropRect: rect)
        }
        return cgImg
    }
    
    func detectAndCrop(cgImg:CGImage) -> CGImage {
        if let rect = self.detectEdges(cgImg: cgImg){
            return self.crop(cgImg: cgImg, rect: rect)
        }
        return cgImg
    }
}


