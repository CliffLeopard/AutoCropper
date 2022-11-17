//
//  Point+.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/21.
//

import Foundation
import opencv2

extension Point2f {
    func toPoint2i() -> Point2i {
        return Point2i(x: Int32(self.x), y: Int32(self.y))
    }
}

extension Point2i {
    func toPoint2f() -> Point2f {
        return Point2f(x: Float(self.x),  y: Float(self.y))
    }
    func toCGPoint() -> CGPoint {
        return CGPoint(x: CGFloat(self.x), y: CGFloat(self.y))
    }
}

extension Float {
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
}

extension CGPoint {
    func toPoint2i() -> Point2i {
        return Point2i(x: Int32(self.x), y: Int32(self.y))
    }
    
    func toPoint2f() -> Point2f {
        return Point2f(x: Float(self.x), y: Float(self.y))
    }
    
    func scale(degree:CGFloat) -> CGPoint {
        return CGPoint(x: self.x * degree, y: self.y * degree)
    }
}
