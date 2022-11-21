//
//  CVCropper.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/12.
//

import Foundation
import CoreImage
import opencv2

class CVCropper {
    // 计算裁剪区域
    static func detectEdges(cgImg:CGImage) -> SCropRect? {
        let mat = Mat(cgImage: cgImg)
        // 高斯模糊
        Imgproc.GaussianBlur(src: mat, dst: mat, ksize: Size2i(width: 11, height: 11), sigmaX: 0)
        // 二值化
        Imgproc.cvtColor(src: mat, dst: mat, code: .COLOR_BGR2GRAY)
        // canny边缘检测
        Imgproc.Canny(image: mat, edges: mat, threshold1: 10, threshold2: 20)
        // 边缘膨胀
        Imgproc.dilate(src: mat, dst: mat, kernel: Mat(),anchor:Point2i(x: -1, y: -1))
        // 收敛
        Imgproc.threshold(src: mat, dst: mat, thresh: 0, maxval: 255, type: .THRESH_OTSU)
        
        return CVCropper.findCropRect(mat: mat)
    }
    
    static func findCropRect(mat:Mat) -> SCropRect? {
        // 获取边界像素点
        var contours:[[Point2i]] = [[]]
        Imgproc.findContours(image: mat, contours: &contours, hierarchy: Mat(), mode: .RETR_LIST, method: .CHAIN_APPROX_SIMPLE)
        
        // 过滤之后的边界
        var filtedConters:Array<[Point2f]> = Array()
        var maxArea:Double = -1
        var maxAreaContour:[Point2f] = []
        let frameArea = Double(mat.cols()) * Double(mat.rows())
        
        contours.forEach { ct in
            let contour = ct.map { pt in
                Point2f(x: Float(pt.x), y: Float(pt.y))
            }
            // 计算周长
            let arc = Imgproc.arcLength(curve: contour, closed: true)
            
            //多边形逼近
            var approxCurve:[Point2f] = []
            
            if(contour.count == 4) {
                approxCurve = contour
            } else {
                Imgproc.approxPolyDP(curve: contour, approxCurve: &approxCurve, epsilon: 0.028*arc, closed: true)
            }
            
            if(approxCurve.count == 4){
                filtedConters.append(approxCurve)
                let approx2i = approxCurve.map { pt in
                    Point2i(x: Int32(pt.x), y: Int32(pt.y))
                }
                
                // 凸轮廓
                let isContourConvex = Imgproc.isContourConvex(contour: approx2i)
                if(isContourConvex) {
                    // 面积
                    let contourArea = Imgproc.contourArea(contour: MatOfPoint(array: approx2i))
                    if(contourArea > maxArea) {
                        maxArea = contourArea
                        maxAreaContour = approxCurve
                    }
                }
            }
        }
        
        if(maxArea*200 >= frameArea) {
            let cropRect = buildRect(ct: maxAreaContour)
            return cropRect
        }
        return nil
    }
    
    // 绘制裁剪区域边框
    static  func drawCropRect(cgImg: CGImage, cropRect: SCropRect) -> CGImage {
        let originMat = Mat(cgImage: cgImg)
        let topLeft = cropRect.topLeft.toPoint2i()
        let bottomLeft = cropRect.bottomLeft.toPoint2i()
        let topRight = cropRect.topRight.toPoint2i()
        let bottomRight = cropRect.bottomRight.toPoint2i()
        Imgproc.line(img: originMat, pt1: topLeft, pt2: bottomLeft, color: Scalar(0,0,255),thickness: 8)
        Imgproc.line(img: originMat, pt1: topLeft, pt2: topRight, color: Scalar(0,0,255),thickness: 8)
        Imgproc.line(img: originMat, pt1: topRight, pt2: bottomRight, color: Scalar(0,0,255),thickness: 8)
        Imgproc.line(img: originMat, pt1: bottomLeft, pt2: bottomRight, color: Scalar(0,0,255),thickness: 8)
        return originMat.toCGImage()
    }
    
    // 裁剪
    static  func crop(cgImg:CGImage, rect:SCropRect) -> CGImage {
        let top = cacultateDistance(a: rect.topLeft, b: rect.topRight)
        let button = cacultateDistance(a: rect.bottomLeft, b: rect.bottomRight)
        let left = cacultateDistance(a: rect.topLeft, b: rect.bottomLeft)
        let right = cacultateDistance(a: rect.topRight, b: rect.bottomRight)
        let dstWidth =  (top  + button) / 2
        let dstHeight = (left + right) / 2
        
        let frameMat = MatOfPoint2f(array: [
            Point2f(x: 0, y: 0),
            Point2f(x: Float(dstWidth), y: 0),
            Point2f(x: Float(dstWidth), y: Float(dstHeight)),
            Point2f(x: 0, y: Float(dstHeight))
        ])
        
        let cropMat = MatOfPoint2f(array: [
            rect.topLeft.toPoint2f(),
            rect.topRight.toPoint2f(),
            rect.bottomRight.toPoint2f(),
            rect.bottomLeft.toPoint2f()
        ])
        
        // 透视角度转换
        let transformMat = Imgproc.getPerspectiveTransform(src: cropMat, dst: frameMat)
        
        // 透视剪切目的Mat
        let dstMat = Mat(size: Size2i(width: Int32(dstWidth), height: Int32(dstHeight)), type: CvType.CV_32F)
        
        // 进行透视裁剪
        Imgproc.warpPerspective(
            src: Mat(cgImage: cgImg),
            dst: dstMat, M: transformMat,
            dsize: Size2i(width: Int32(dstWidth), height: Int32(dstHeight))
        )
        return dstMat.toCGImage()
    }
    
    // 计算亮点距离
    private static  func cacultateDistance(a:CGPoint, b:CGPoint) -> CGFloat {
        let x =  abs(a.x - b.x)
        let y = abs(a.y - b.y)
        return sqrt(x*x + y*y)
    }
    
    
    // 排序 leftTop, leftBottom, rightBottom, rightTop
    private static func buildRect(ct:[Point2f]) -> SCropRect {
        var rect = SCropRect()
        let contour = ct.sorted { p1, p2 in
            p1.x < p2.x
        }
        
        if(contour[0].y < contour[1].y) {
            rect.topLeft = CGPointMake(contour[0].x.toCGFloat(), contour[0].y.toCGFloat())
            rect.bottomLeft = CGPointMake(contour[1].x.toCGFloat(), contour[1].y.toCGFloat())
        } else {
            rect.topLeft = CGPointMake(contour[1].x.toCGFloat(), contour[1].y.toCGFloat())
            rect.bottomLeft = CGPointMake(contour[0].x.toCGFloat(), contour[0].y.toCGFloat())
        }
        
        
        if(contour[2].y < contour[3].y) {
            rect.topRight = CGPointMake(contour[2].x.toCGFloat(), contour[2].y.toCGFloat())
            rect.bottomRight = CGPointMake(contour[3].x.toCGFloat(), contour[3].y.toCGFloat())
        } else {
            rect.topRight = CGPointMake(contour[3].x.toCGFloat(), contour[3].y.toCGFloat())
            rect.bottomRight = CGPointMake(contour[2].x.toCGFloat(), contour[2].y.toCGFloat())
        }
        return rect
    }
    
    // 构造边框Mat
    private static func buildFrameMat(uiImage:UIImage) -> Mat {
        let originWidth = uiImage.size.width
        let originHeight = uiImage.size.height
        return  MatOfPoint2f(array: [
            Point2f(x: 0, y: 0),
            Point2f(x: Float(originWidth), y: 0),
            Point2f(x: Float(originWidth), y: Float(originHeight)),
            Point2f(x: 0, y: Float(originHeight))
        ])
    }
}
