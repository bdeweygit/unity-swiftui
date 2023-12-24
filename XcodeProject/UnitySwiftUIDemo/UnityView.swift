//
//  UnityView.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI

struct UnityView: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        let vc = UIViewController()
        Unity.shared.superview = vc.view
        return vc
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {}
}

#Preview {
    UnityView()
}
