//
//  UIViewContainer.swift
//  UnitySwiftUI
//
//  Created by Benjamin Dewey on 12/31/23.
//

import SwiftUI

struct UIViewContainer: UIViewRepresentable {
    let containee: UIView

    func makeUIView(context: Context) -> UIView {
        return containee
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
