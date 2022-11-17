//
//  SCropRect.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/26.
//

import Foundation
import opencv2

struct SCropRect {
    var topLeft:CGPoint
    var topRight:CGPoint
    var bottomLeft:CGPoint
    var bottomRight:CGPoint
    var dragPoint:CGPoint?
    
    init() {
        self.topLeft = CGPoint()
        self.topRight = CGPoint()
        self.bottomLeft = CGPoint()
        self.bottomRight = CGPoint()
        self.dragPoint = nil
    }
    
    init(width:CGFloat,heiht:CGFloat) {
        self.topLeft = CGPointMake(0, 0)
        self.topRight = CGPointMake(width, 0)
        self.bottomLeft = CGPointMake(0, heiht)
        self.bottomRight = CGPointMake(width, heiht)
    }
    
    init(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint,dragPoint:CGPoint? = nil) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.dragPoint = dragPoint
    }
    
    init(topLeft: Point2f, topRight: Point2f, bottomLeft: Point2f, bottomRight: Point2f) {
        self.topLeft = CGPoint(x: CGFloat(topLeft.x), y: CGFloat(topLeft.y))
        self.topRight = CGPoint(x: CGFloat(topRight.x), y: CGFloat(topRight.y))
        self.bottomLeft = CGPoint(x: CGFloat(topLeft.x), y: CGFloat(topLeft.y))
        self.bottomRight = CGPoint(x: CGFloat(bottomRight.x), y: CGFloat(bottomRight.y))
    }
    
    init(cirf:CIRectangleFeature) {
        self.topLeft = cirf.topLeft
        self.topRight = cirf.topRight
        self.bottomLeft = cirf.bottomLeft
        self.bottomRight = cirf.bottomRight
    }
    
    func toArray()-> [CGPoint] {
        return [topLeft,topRight,bottomLeft,bottomRight]
    }

    func toLineArray() -> [CGPoint] {
        return [topLeft,topRight, bottomRight,bottomLeft,topLeft]
    }
    
    func sort() -> SCropRect {
        var rect = SCropRect()
        let array = self.toArray().sorted { p1, p2 in
            p1.x < p2.x
        }

        if(array[0].y < array[1].y) {
            rect.topLeft = array[0]
            rect.bottomLeft = array[1]
        } else {
            rect.topLeft = array[1]
            rect.bottomLeft = array[0]
        }


        if(array[2].y < array[3].y) {
            rect.topRight = array[2]
            rect.bottomRight = array[3]
        } else {
            rect.topRight = array[3]
            rect.bottomRight = array[2]
        }
        return rect
    }
    
    func scale(degree:CGFloat) -> SCropRect {
        return SCropRect(topLeft: self.topLeft.scale(degree: degree),
                         topRight: self.topRight.scale(degree: degree),
                         bottomLeft: self.bottomLeft.scale(degree: degree),
                         bottomRight: self.bottomRight.scale(degree: degree),
                         dragPoint:self.dragPoint)
    }
    
    
    func topLineRect(_ width: Double = 1)-> SCropRect {
        return SCropRect(
            topLeft:self.topLeft,
            topRight: self.topRight,
            bottomLeft: CGPoint(x:self.topLeft.x,y:self.topLeft.y + width),
            bottomRight: CGPoint(x:self.topRight.x, y:self.topRight.y + width)
        )
    }
    
    func  bottomLineRect(_ width: Double = 1)-> SCropRect {
        return SCropRect(
            topLeft:  CGPoint(x:self.bottomLeft.x,y:self.bottomLeft.y - width),
            topRight: CGPoint(x:self.bottomRight.x, y:self.bottomRight.y - width),
            bottomLeft: self.bottomLeft,
            bottomRight: self.bottomRight
        )
    }
    
    func leftLineRect(_ width: Double = -1) -> SCropRect {
        return SCropRect(
            topLeft: self.topLeft,
            topRight: CGPoint(x: self.topLeft.x + width, y: self.topLeft.y),
            bottomLeft: self.bottomLeft,
            bottomRight: CGPoint(x:self.bottomLeft.x + width, y:self.bottomLeft.y)
        )
    }
    
    func rightLineRect(_ width: Double = -1) -> SCropRect {
        return SCropRect(
            topLeft: CGPoint(x:self.topRight.x - width,y:self.topRight.y),
            topRight: self.topRight,
            bottomLeft:  CGPoint(x:self.bottomRight.x - width,y:self.bottomRight.y),
            bottomRight: self.bottomRight
        )
    }
}

