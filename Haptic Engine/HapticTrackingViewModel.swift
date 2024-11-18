//
//  HapticTrackingViewModel.swift
//  Haptic Engine
//
//  Created by Shahzaib Ali on 18/11/2024.
//

import Foundation
import UIKit
import SwiftUI
class HapticTrackingViewModel: ObservableObject {

    @Published private(set) var randomDotModel = DotModel(position: .zero, size: 0, color: .blue)
    @Published private(set) var fingerDotModel = DotModel(position: .zero, size: 0, color: .red)
    @Published private(set) var isDragging = false
    @Published private(set) var backgroundFlickerIntensity: CGFloat = 0
    @Published private(set) var opacity: CGFloat = 0

    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private var MAX_DISTANCE : CGFloat = 0
    
    private func adaptiveSizes(for geometry: GeometryProxy) -> CGFloat {
        let screenSmallestDimension = min(geometry.size.width, geometry.size.height)
        
        
        let baseDotSize = screenSmallestDimension * 0.20
    
      
        MAX_DISTANCE = geometry.size.height
        return baseDotSize
    }

    func onAppear(in geometry: GeometryProxy) {
        let baseDotSize = adaptiveSizes(for: geometry)
        randomDotModel = DotModel(position: randomPosition(in: geometry.size, dotSize: baseDotSize),
                                  size: baseDotSize,
                                  color: .blue)
        fingerDotModel = DotModel(position: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                                  size: baseDotSize,
                                  color: .red)
       
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            randomDotModel.size = 100
        }
        if hasFeedbackSupport {
            impactFeedback.prepare()
            selectionFeedback.prepare()
        }
    }

    func onDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        isDragging = true
        fingerDotModel.position = constrainPosition(value.location, in: geometry.size, dotSize: fingerDotModel.size)

        let distance = calculateDistance(from: fingerDotModel.position, to: randomDotModel.position)
        if distance < fingerDotModel.size {
            if hasFeedbackSupport {
                impactFeedback.impactOccurred(intensity: 1.0)
            } else {
                withAnimation(.easeInOut(duration: 0.1).repeatForever() ){
                    opacity = opacity > 0 ? 0 : 1
                }
            }
            updateRandomDotModel(in: geometry.size, dotSize: randomDotModel.size)
        } else if distance < MAX_DISTANCE {
            let intensity = 1.0 - (distance / MAX_DISTANCE)
            print("INTENSITY ",intensity)
            backgroundFlickerIntensity = intensity
            if hasFeedbackSupport {
                selectionFeedback.prepare()
                selectionFeedback.selectionChanged()
                if distance < randomDotModel.size * 4 {
                    impactFeedback.impactOccurred(intensity: intensity)
                }
            } else {
                withAnimation(.easeInOut(duration: 0.1).repeatForever()) {
                    opacity = opacity > 0 ? 0 : 1
                }
            }
        } else {
            backgroundFlickerIntensity = 0
        }
    }

    func onDragEnded() {
        isDragging = false
    }

    private func calculateDistance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let deltaX = point2.x - point1.x
        let deltaY = point2.y - point1.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }

    private func updateRandomDotModel(in size: CGSize, dotSize: CGFloat) {
        let xRange = dotSize/2...size.width-dotSize/2
        let yRange = dotSize/2...size.height-dotSize/2
        DispatchQueue.main.async {
            self.randomDotModel = DotModel(position: CGPoint(x: CGFloat.random(in: xRange),
                                                       y: CGFloat.random(in: yRange)),
                                      size: dotSize,
                                      color: .blue)
        }
       
    }

    private func constrainPosition(_ position: CGPoint, in size: CGSize, dotSize: CGFloat) -> CGPoint {
        let halfDotSize = dotSize / 2
        return CGPoint(x: min(max(position.x, halfDotSize), size.width - halfDotSize),
                       y: min(max(position.y, halfDotSize), size.height - halfDotSize))
    }

    
    private var hasFeedbackSupport: Bool {
        if let majorVersion = Int(UIDevice.current.systemVersion.components(separatedBy: ".").first ?? "0") {
            return majorVersion >= 13

        } else {
            return false
        }
    }

    private func randomPosition(in size: CGSize, dotSize: CGFloat) -> CGPoint {
        let xRange = dotSize/2...size.width-dotSize/2
        let yRange = dotSize/2...size.height-dotSize/2
        return CGPoint(x: CGFloat.random(in: xRange),
                       y: CGFloat.random(in: yRange))
    }
}
