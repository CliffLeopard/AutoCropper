//
//  MagifierGlassModifier.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/10.
//

import SwiftUI

extension View {
    func magifierGlass(showMag:Bool) -> some View {
        return modifier(MagifierGlassModifier(showMag: showMag))
    }
}

struct MagifierGlassModifier: ViewModifier {
    @State var showMag:Bool
    @State var contentPosition:CGPoint = CGPointMake(0, 0)
    @State var postion:CGPoint = CGPointMake(0, 0)
    @State var scale :CGFloat = 2.0
    
    @State var showContent = true
    @State var originSize:CGSize = CGSize(width: 0, height: 0)
    let size = CGSizeMake(80, 80)
    let r: CGFloat = 40
    func body(content: Content) -> some View {
        if showMag {
            ZStack {
                content.overlay {
                    GeometryReader { reader in
                        content.scaleEffect(self.scale)
                            .position(x: reader.size.width * scale / 2,y: reader.size.height * scale / 2)  // topLeading 对齐
                            .offset(x: -self.postion.x*self.scale + self.size.width / 2, y:-self.postion.y*self.scale + self.size.height / 2 )
                            .clipShape(MagifierShape(center: CGPointMake(self.size.width / 2, self.size.height / 2)))
                        //                            .mask(alignment: .topLeading) {
                        //                                Circle().frame(width: self.size.width, height: self.size.height)
                        //                            }
                        getClassView()
                    }.allowsHitTesting(false)
                }.gesture(
                    DragGesture()
                        .onChanged({ value in
                            self.postion = value.location
                        })
                )
            }.onChange(of: self.originSize) { newValue in
                debugPrint("Get Origin Size", newValue)
            }
        } else {
            content
        }
    }
    
    func getClassView() -> some View {
        ZStack {
            Path { path in
                path.addLines([
                    CGPointMake(size.width/2, 25),
                    CGPointMake(size.width/2, size.height-25),
                ])
                
                path.addLines([
                    CGPointMake(25, size.height/2),
                    CGPointMake(size.width-25, size.height/2),
                ])
            }
            .stroke(lineWidth: 2)
            .foregroundColor(Color.black)
            
            Circle()
                .stroke(lineWidth: 2)
                .foregroundColor(Color.green)
                .frame(width: size.width, height: size.height,alignment: .topLeading)
                .position(x:size.width/2, y:size.height/2)
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
}
