//
//  View+.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import Foundation
import SwiftUI

extension View {
    func overlay<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View {
        let overlayView = content()
        return self.overlay(overlayView,alignment: alignment)
    }
    
    func like_task(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15.0, *) {
            return self.task(priority: priority,action)
        } else {
            return self.onAppear {
                Task(priority: priority) {
                    await action()
                }
            }
        }
    }
    
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        let image = controller.view.asUIImage()
        controller.view.removeFromSuperview()
        return image
    }
}

extension UIView {
    public func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}


