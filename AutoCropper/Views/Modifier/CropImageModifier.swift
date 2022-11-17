//
//  WebViewModifiter.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/2.
//

import SwiftUI
import opencv2


protocol ImageModifier {
    associatedtype Body : View
    func body(image: Image) -> Self.Body
}

extension Image {
    func modifier<M>(_ modifier: M) -> some View where M: ImageModifier {
        modifier.body(image: self)
    }
    
    func showCroper(_ cropRect:Binding<SCropRect?>,originImageWidth:CGFloat?, showCrop:Binding<Bool>) -> some View {
        return modifier(CropRectModifier(cropRect: cropRect,originImageWidth: originImageWidth, showCrop: showCrop))
    }
}

public struct CropRectModifier: ImageModifier {
    @Binding var cropRect:SCropRect?
    let originImageWidth:CGFloat?
    @Binding var showCrop:Bool
    let scale :CGFloat = 2.0
    let size = CGSizeMake(80, 80)
    let anchorRadius:CGFloat = 8
    public func body(image: Image) ->  some View {
        return image
            .resizable()
            .scaledToFit()
            .overlay{
                GeometryReader { reader in
                    if self.showCrop,
                       let crop = self.cropRect,
                       let originWidth = self.originImageWidth,
                       let degree = reader.size.width / originWidth,
                       let cropRect = crop.scale(degree: degree) {
                        ZStack {
                            borderLine(cropRect: cropRect)
                            borderPoints(cropRect: cropRect,degree:degree, size:reader.size)
                            middlePoints(cropRect: cropRect,degree:degree, size:reader.size)
                            
                            if let dragPoint = cropRect.dragPoint {
                                image.resizable()
                                    .scaledToFit()
                                    .scaleEffect(self.scale)
                                    .position(x: reader.size.width * scale / 2,y: reader.size.height * scale / 2)  // topLeading 对齐
                                    .offset(x: -dragPoint.x*self.scale + self.size.width / 2,
                                            y: -dragPoint.y*self.scale + self.size.height / 2 )
                                    .clipShape(MagifierShape(center: CGPointMake(self.size.width / 2, self.size.height / 2)))
                                    .allowsHitTesting(false)
                                
                                Path { path in
                                    path.addLines([
                                        CGPointMake(size.width/2, 20),
                                        CGPointMake(size.width/2, size.height-20),
                                    ])
                                    
                                    path.addLines([
                                        CGPointMake(20, size.height/2),
                                        CGPointMake(size.width-20, size.height/2),
                                    ])
                                }
                                .stroke(lineWidth: 1)
                                .foregroundColor(Color.black)
                                
                                Circle()
                                    .stroke(lineWidth: 2)
                                    .foregroundColor(Color.green)
                                    .frame(width: size.width, height: size.height,alignment: .topLeading)
                                    .position(x:size.width/2, y:size.height/2)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
    }
    
    func borderLine(cropRect:SCropRect) -> some View {
        return Path { path in
            path.addLines([cropRect.topLeft, cropRect.topRight,cropRect.bottomRight, cropRect.bottomLeft,cropRect.topLeft])
        }
        .stroke(lineWidth:2)
        .foregroundColor(Color.orange)
    }
    
    func borderPoints(cropRect:SCropRect, degree:CGFloat, size:CGSize) -> some View {
        return ZStack {
            // topLeft
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPoint(x: cropRect.topLeft.x - anchorRadius, y: cropRect.topLeft.y - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
            }
            .foregroundColor(Color.purple)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        if value.location.x > 0,
                           value.location.y > 0,
                           value.location.x < size.width,
                           value.location.y < size.height {
                            let originLocation = value.location.scale(degree: 1 / degree)
                            let approch = Imgproc.isContourConvex(contour: [
                                value.location.toPoint2i(),
                                cropRect.topRight.toPoint2i(),
                                cropRect.bottomRight.toPoint2i(),
                                cropRect.bottomLeft.toPoint2i()
                            ])
                            
                            if(approch) {
                                self.cropRect?.dragPoint = value.location
                                self.cropRect?.topLeft = originLocation
                            }
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
            
            
            // topRight
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPoint(x: cropRect.topRight.x - anchorRadius, y: cropRect.topRight.y - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
            }
            .foregroundColor(Color.purple)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        if ( value.location.x > 0
                             && value.location.y > 0
                             && value.location.x < size.width
                             && value.location.y < size.height) {
                            let originLocation = value.location.scale(degree: 1/degree)
                            let approch = Imgproc.isContourConvex(contour: [
                                cropRect.topLeft.toPoint2i(),
                                value.location.toPoint2i(),
                                cropRect.bottomRight.toPoint2i(),
                                cropRect.bottomLeft.toPoint2i()
                            ])
                            
                            if(approch) {
                                self.cropRect?.dragPoint = value.location
                                self.cropRect?.topRight = originLocation
                            }
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
            
            
            // bottomRight
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPoint(x: cropRect.bottomRight.x - anchorRadius, y: cropRect.bottomRight.y - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
            }
            .foregroundColor(Color.purple)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        if ( value.location.x > 0
                             && value.location.y > 0
                             && value.location.x < size.width
                             && value.location.y < size.height) {
                            let originLocation = value.location.scale(degree: 1/degree)
                            let approch = Imgproc.isContourConvex(contour: [
                                cropRect.topLeft.toPoint2i(),
                                cropRect.topRight.toPoint2i(),
                                value.location.toPoint2i(),
                                cropRect.bottomLeft.toPoint2i()
                            ])
                            
                            if(approch) {
                                self.cropRect?.dragPoint = value.location
                                self.cropRect?.bottomRight = originLocation
                            }
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
            
            //bottomLeft
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPoint(x: cropRect.bottomLeft.x - anchorRadius, y: cropRect.bottomLeft.y - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
            }
            .foregroundColor(Color.purple)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        if ( value.location.x > 0
                             && value.location.y > 0
                             && value.location.x < size.width
                             && value.location.y < size.height) {
                            let originLocation = value.location.scale(degree: 1/degree)
                            let approch = Imgproc.isContourConvex(contour: [
                                cropRect.topLeft.toPoint2i(),
                                cropRect.topRight.toPoint2i(),
                                cropRect.bottomRight.toPoint2i(),
                                value.location.toPoint2i()
                            ])
                            
                            if(approch) {
                                self.cropRect?.dragPoint = value.location
                                self.cropRect?.bottomLeft = originLocation
                            }
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
        }
    }
    
    func middlePoints(cropRect:SCropRect,degree:CGFloat, size:CGSize) -> some View {
        return  ZStack{
            //middleTop
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPointMake((cropRect.topLeft.x + cropRect.topRight.x)/2 - anchorRadius , (cropRect.topLeft.y + cropRect.topRight.y)/2 - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
                
            }
            .foregroundColor(Color.green)
            .gesture(DragGesture()
                .onChanged({ value in
                    let lastTranslation = (cropRect.topLeft.y + cropRect.topRight.y)/2 - value.startLocation.y
                    let gap = value.translation.height - lastTranslation
                    let tLy = cropRect.topLeft.y + gap
                    let tRy = cropRect.topRight.y + gap
                    
                    if tLy >= anchorRadius,
                       tRy >= anchorRadius,
                       tLy <= cropRect.bottomLeft.y - anchorRadius,
                       tRy <= cropRect.bottomRight.y - anchorRadius {
                        self.cropRect?.dragPoint = value.location
                        self.cropRect?.topLeft.y += gap / degree
                        self.cropRect?.topRight.y += gap / degree
                    }
                })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
            
            // middleRight
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPointMake((cropRect.bottomRight.x + cropRect.topRight.x)/2 - anchorRadius , (cropRect.bottomRight.y + cropRect.topRight.y)/2 - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
                
            }
            .foregroundColor(Color.green)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        
                        let lastTranslation = (cropRect.topRight.x + cropRect.bottomRight.x)/2 - value.startLocation.x
                        let gap = value.translation.width - lastTranslation
                        let tRx = cropRect.topRight.x + gap
                        let bRx = cropRect.bottomRight.x + gap
                        
                        if tRx < size.width - anchorRadius,
                           bRx < size.width - anchorRadius,
                           tRx > cropRect.topLeft.x + anchorRadius*2,
                           bRx > cropRect.bottomLeft.x + anchorRadius*2 {
                            self.cropRect?.dragPoint = value.location
                            self.cropRect?.topRight.x += gap / degree
                            self.cropRect?.bottomRight.x += gap / degree
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
            
            // middleBottom
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPointMake((cropRect.bottomRight.x + cropRect.bottomLeft.x)/2 - anchorRadius ,
                                                   (cropRect.bottomRight.y + cropRect.bottomLeft.y)/2 - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
                
            }
            .foregroundColor(Color.green)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        
                        let lastTranslation = (cropRect.bottomLeft.y + cropRect.bottomRight.y)/2 - value.startLocation.y
                        let gap = value.translation.height - lastTranslation
                        let bLy = cropRect.bottomLeft.y  + gap
                        let bRy = cropRect.bottomRight.y + gap
                        
                        if bLy > cropRect.topLeft.y + anchorRadius,
                           bRy > cropRect.topRight.y + anchorRadius,
                           bLy < size.height - anchorRadius,
                           bRy < size.height - anchorRadius {
                            self.cropRect?.dragPoint = value.location
                            self.cropRect?.bottomLeft.y += gap / degree
                            self.cropRect?.bottomRight.y += gap / degree
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
            
            // middleLeft
            Path { path in
                path.addEllipse(
                    in: CGRect(origin: CGPointMake((cropRect.topLeft.x + cropRect.bottomLeft.x)/2 - anchorRadius , (cropRect.topLeft.y + cropRect.bottomLeft.y)/2 - anchorRadius),
                               size: CGSizeMake(2*anchorRadius, 2*anchorRadius)))
            }
            .foregroundColor(Color.green)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        let lastTranslation = (cropRect.bottomLeft.x + cropRect.topLeft.x)/2 - value.startLocation.x
                        let gap = value.translation.width - lastTranslation
                        let tLx = cropRect.topLeft.x + gap
                        let bLx = cropRect.bottomLeft.x + gap
                        
                        if tLx > anchorRadius,
                           bLx > anchorRadius,
                           tLx < cropRect.topRight.x - anchorRadius*2,
                           bLx < cropRect.bottomRight.x - anchorRadius*2 {
                            self.cropRect?.dragPoint = value.location
                            self.cropRect?.bottomLeft.x += gap / degree
                            self.cropRect?.topLeft.x += gap / degree
                        }
                    })
                    .onEnded({ _ in
                        self.cropRect?.dragPoint = nil
                    })
            )
        }
    }
}

struct MagifierShape: Shape {
    @State var center:CGPoint
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: center,
                    radius: center.x,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 360.01), clockwise: true)
        return path
    }
}
