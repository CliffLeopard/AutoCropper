//
//  MultiPressViewModifier.swift
//  SwiftConchs
//
//  Created by CliffLeopard on 2022/6/24.
//

import Foundation
import SwiftUI

// 各种手势扩展
public extension View {
    func multiPress(minimumDuration: Double  = 0.5,
                    minimumDistance: CGFloat = 10,
                    coordinateSpace: CoordinateSpace = .local,
                    onTouchScreen:  @escaping () ->Void = {},
                    onClick:        @escaping () ->Void = {},
                    onLongClick:    @escaping () ->Void = {},
                    onLongClickUp:  @escaping () ->Void = {},
                    onDragProcess:  @escaping (_ value: DragGesture.Value, _ direction:DragDirection, _ length: CGFloat)  ->  Void = { value, direction, length in },
                    onSwipeProcess: @escaping (_ value: DragGesture.Value, _ direction:DragDirection, _ length: CGFloat)  ->  Void = { value, direction, length in },
                    onSwipeUp:      @escaping (_ value: DragGesture.Value) -> Void = { value in },
                    onLongClickAndDragUp: @escaping (_ value: DragGesture.Value) -> Void = { value in }) -> some View {
        
        modifier(MultiPressViewModifier(
            minimumDuration:minimumDuration,
            minimumDistance:minimumDistance,
            coordinateSpace:coordinateSpace,
            onTouchScreen:onTouchScreen,
            onClick:onClick,
            onLongClick:onLongClick,
            onLongClickUp:onLongClickUp,
            onDragProcess:onDragProcess,
            onSwipeProcess:onSwipeProcess,
            onSwipeUp:onSwipeUp,
            onLongClickAndDragUp:onLongClickAndDragUp))
    }
}

public struct MultiPressViewModifier: ViewModifier {
    @State var longClickState = 0 // 0 没有长按，1:触碰屏幕 2:长按生效
    let minimumDuration : Double
    let minimumDistance : CGFloat
    let coordinateSpace : CoordinateSpace
    
    let onTouchScreen:        ()  ->  Void
    let onClick:              ()  ->  Void
    let onLongClick:          ()  ->  Void
    let onLongClickUp:        ()  ->  Void
    let onDragProcess:        (_ value: DragGesture.Value, _ direction:DragDirection, _ length: CGFloat)  ->  Void
    let onSwipeProcess:       (_ value: DragGesture.Value, _ direction:DragDirection, _ length: CGFloat)  ->  Void
    let onSwipeUp:            (_ value: DragGesture.Value) -> Void
    let onLongClickAndDragUp: (_ value: DragGesture.Value) -> Void
    
    public func body(content: Content) -> some View {
        let longGesture = LongPressGesture(minimumDuration: minimumDuration, maximumDistance: minimumDistance)
            .onChanged { value in
                if value {
                    longClickState = 1
                    onTouchScreen()
                }
            }
            .onEnded { value in
                if value {
                    longClickState = 2
                    onLongClick()
                }
            }
        let dragGesture = DragGesture(minimumDistance: self.minimumDistance, coordinateSpace: self.coordinateSpace)
            .onChanged { newValue in
                let change = getDirection(value: newValue)
                if longClickState == 2 {
                    onDragProcess(newValue,change.0, change.1)
                } else {
                    onSwipeProcess(newValue,change.0, change.1)
                }
            }
        
        let tapGesture = TapGesture()
            .onEnded { newValue in
                onClick()
            }
        
        let gesture = longGesture.simultaneously(with: dragGesture)
            .onEnded { newValue  in
                if  let second = newValue.second {
                    if longClickState == 2 {
                        onLongClickAndDragUp(second)
                    } else {
                        onSwipeUp( second)
                    }
                } else {
                    onLongClickUp()
                }
                
                longClickState = 0
            }
            .simultaneously(with: tapGesture)
        
        return content.gesture(gesture)
    }
    
    private func getDirection(value: DragGesture.Value) -> (DragDirection,CGFloat) {
        let translation = value.translation
        var direction = DragDirection.none
        var length:CGFloat = 0
        if abs(translation.width) > abs(translation.height) {
            length = abs(translation.width)
            if translation.width > 0 {
                direction =  .right
            } else {
                direction =  .left
            }
        } else {
            length = abs(translation.height)
            if translation.height > 0 {
                direction =  .down
            } else {
                direction =  .up
            }
        }
        return (direction,length)
    }
}


public enum  DragDirection:String {
    case none = "NONE", left = "LEFT", down = "DOWN", right = "RIGHT", up = "UP"
}
