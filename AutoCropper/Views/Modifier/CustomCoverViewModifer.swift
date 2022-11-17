//
//  CustomCoverViewModifer.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/30.
//

import Foundation
import SwiftUI

extension View {
    func customcover<Content:View>(_ present:Binding<Bool>,autoClose:Bool = true, translucency:CGFloat = 0.2, @ViewBuilder content: @escaping () -> Content)->some View {
        return modifier(CustomCoverViewModifer(present:present,autoClose:autoClose,translucency:translucency,container: content))
    }
}

class UIViewTool {
    static func rootController() -> UIViewController? {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }
}

struct CustomCoverViewModifer<Container>:ViewModifier  where Container:View{
    @Binding var present:Bool
    let autoClose:Bool
    let translucency:CGFloat
    let container:() -> Container
    @State private var dialogView :UIView?
    private let bound = UIScreen.main.bounds
    func body(content: Content) -> some View {
        return content.onChange(of: present) { newValue in
            if let controller = UIViewTool.rootController() {
                if dialogView == nil {
                    let childController = UIHostingController(rootView: container()
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded { _ in
                                    if autoClose {
                                        self.present = false
                                    }
                                }
                        ))
                    self.dialogView = childController.view
                }
                if let view = dialogView {
                    if newValue {
                        view.frame = CGRect(x: 0, y: 0, width: bound.width, height: bound.height)
                        view.backgroundColor = UIColor.black.withAlphaComponent(translucency)
                        controller.view.addSubview(view)
                        controller.view.bringSubviewToFront(view)
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0,options: .curveLinear,animations: {
                            view.center.y = view.bounds.height * 1.5
                            
                        })
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1,options: .curveLinear,animations: {
                            view.center.y = view.bounds.height/2
                        })
                    } else {
                        view.removeFromSuperview()
                    }
                }
            }
        }
    }
}
