//
//  ViewfinderView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import SwiftUI

struct CameraPreview: View {
    @Binding var image: Image?
    @Binding var showCrop:Bool
    @Binding var showHelpLine:Bool
    @Binding var cropRect: SCropRect?
    
    let helpLineBorder:CGFloat = 5.0
    
    var camera:Camera
    @State private var touchPosition: CGPoint? = nil
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.width * CameraDataModel.sizeRate)
                    .overlay {
                        if let cropRect = self.cropRect, showCrop == true {
                            Path{ path in
                                path.addLines([
                                    cropRect.topLeft,
                                    cropRect.topRight,
                                    cropRect.bottomRight,
                                    cropRect.bottomLeft,
                                    cropRect.topLeft
                                ])
                            }
                            .stroke(lineWidth: 2)
                            .foregroundColor(Color.purple)
                        }
                    }
                    .overlay {
                        if self.showHelpLine {
                            Path { path in
                                path.move(to: CGPoint(x:CameraDataModel.scaleWidth/3, y: helpLineBorder))
                                path.addLine(to: CGPoint(x:CameraDataModel.scaleWidth/3, y:CameraDataModel.scaleHeight - helpLineBorder))
                                
                                path.move(to: CGPoint(x:CameraDataModel.scaleWidth/3 * 2, y: helpLineBorder))
                                path.addLine(to: CGPoint(x:CameraDataModel.scaleWidth/3 * 2, y:CameraDataModel.scaleHeight - helpLineBorder))
                                
                                path.move(to: CGPoint(x: helpLineBorder, y:CameraDataModel.scaleHeight / 3))
                                path.addLine(to: CGPoint(x:CameraDataModel.scaleWidth - helpLineBorder, y:CameraDataModel.scaleHeight / 3))
                                
                                path.move(to: CGPoint(x: helpLineBorder , y:CameraDataModel.scaleHeight / 3 * 2))
                                path.addLine(to: CGPoint(x:CameraDataModel.scaleWidth - helpLineBorder, y:CameraDataModel.scaleHeight / 3 * 2))
                            }
                            .stroke(lineWidth:1)
                            .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
            }
        }
        
        .overlay(content: {
            if let position = touchPosition {
                Image(systemName: "camera.metering.spot")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.orange)
                    .frame(width: 60.0,height: 40.0)
                    .position(x:position.x,y:position.y)
            }
        })
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged{ gesture in
                    if(abs(gesture.translation.height) > 10){
                        camera.zoom(lenght: gesture.location.y - gesture.startLocation.y)
                    }
                }
                .onEnded{ gesture in
                    let point = gesture.location
                    if( point == gesture.startLocation){
                        touchPosition = point
                        camera.focusOnPosition(position: point)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            touchPosition = nil
                        }
                    } else {
                        camera.zoomEnd(lenght: gesture.location.y - gesture.startLocation.y)
                    }
                }
        )
    }
    
    
    // 暂不使用，低版本适配问题
    func getAnimationCrop(cropRect:SCropRect) -> some View {
        ZStack{
            withAnimation(.easeInOut(duration: 1)) {
                Line(start: cropRect.topLeft, end: cropRect.topRight)
                    .stroke(lineWidth:2)
                    .foregroundColor(Color.purple)
            }
            
            withAnimation(.easeInOut(duration: 1)) {
                Line(start: cropRect.topRight, end: cropRect.bottomRight)
                    .stroke(lineWidth:2)
                    .foregroundColor(Color.purple)
            }
            
            withAnimation(.easeInOut(duration: 1)) {
                Line(start: cropRect.bottomRight, end: cropRect.bottomLeft)
                    .stroke(lineWidth:2)
                    .foregroundColor(Color.purple)
            }
            
            withAnimation(.easeInOut(duration: 1)) {
                Line(start: cropRect.bottomLeft, end: cropRect.topLeft)
                    .stroke(lineWidth:2)
                    .foregroundColor(Color.purple)
            }
        }
    }
    
    // 动画添加辅助线，暂时不用，低版本适配
    func getHelpLine() -> some View {
        ZStack {
            Line(start: CGPoint(x:CameraDataModel.scaleWidth/3, y: helpLineBorder),
                 end: CGPoint(x:CameraDataModel.scaleWidth/3, y:CameraDataModel.scaleHeight - helpLineBorder))
            .stroke(lineWidth:1)
            .foregroundColor(Color.white.opacity(0.7))
            
            Line(start: CGPoint(x:CameraDataModel.scaleWidth/3 * 2, y: helpLineBorder),
                 end: CGPoint(x:CameraDataModel.scaleWidth/3 * 2, y:CameraDataModel.scaleHeight - helpLineBorder))
            .stroke(lineWidth:1)
            .foregroundColor(Color.white.opacity(0.7))
            
            Line(start: CGPoint(x: helpLineBorder, y:CameraDataModel.scaleHeight / 3),
                 end: CGPoint(x:CameraDataModel.scaleWidth - helpLineBorder, y:CameraDataModel.scaleHeight / 3))
            .stroke(lineWidth:1)
            .foregroundColor(Color.white.opacity(0.7))
            
            Line(start: CGPoint(x: helpLineBorder , y:CameraDataModel.scaleHeight / 3 * 2),
                 end: CGPoint(x:CameraDataModel.scaleWidth - helpLineBorder, y:CameraDataModel.scaleHeight / 3 * 2))
            .stroke(lineWidth:1)
            .foregroundColor(Color.white.opacity(0.7))
        }
    }
}
