//
//  HapticTrackingViewModel.swift
//  Haptic Engine
//
//  Created by Shahzaib Ali on 18/11/2024.
//

import Foundation
import UIKit
import CoreHaptics
import SwiftUI

class HapticTrackingViewModel: ObservableObject {

    
    @Published  var rippleScale: CGFloat = 0.1
     @Published  var rippleOpacity: Double = 0
    
    
    @Published private(set) var randomDotModel = DotModel(position: .zero, size: 0, color: .blue)
    @Published private(set) var fingerDotModel = DotModel(position: .zero, size: 0, color: .red)
    @Published private(set) var isDragging = false
    @Published private(set) var backgroundFlickerIntensity: CGFloat = 0
    @Published private(set) var opacity: CGFloat = 0

    private var intensityParameter: CHHapticDynamicParameter?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer!
    private var engine: CHHapticEngine!
    
    

    private var MAX_DISTANCE : CGFloat = 0

   
    private let initialIntensity: Float = 1.0
     private let initialSharpness: Float = 0.5
    
    func createAndStartHapticEngine() {
          
          // Create and configure a haptic engine.
          do {
              engine = try CHHapticEngine()
          } catch let error {
              fatalError("Engine Creation Error: \(error)")
          }
          
          // Mute audio to reduce latency for collision haptics.
          engine.playsHapticsOnly = true
          
          // The stopped handler alerts you of engine stoppage.
          engine.stoppedHandler = { reason in
              print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
              switch reason {
              case .audioSessionInterrupt:
                  print("Audio session interrupt")
              case .applicationSuspended:
                  print("Application suspended")
              case .idleTimeout:
                  print("Idle timeout")
              case .systemError:
                  print("System error")
              case .notifyWhenFinished:
                  print("Playback finished")
              case .gameControllerDisconnect:
                  print("Controller disconnected.")
              case .engineDestroyed:
                  print("Engine destroyed.")
              @unknown default:
                  print("Unknown error")
              }
          }
          
          // The reset handler provides an opportunity to restart the engine.
          engine.resetHandler = {
              
              print("Reset Handler: Restarting the engine.")
              
              do {
                  // Try restarting the engine.
                  try self.engine.start()
                  
                  // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
//                  self.engineNeedsStart = false
                  
                  // Recreate the continuous player.
                  self.createContinuousHapticPlayer()
                  
              } catch {
                  print("Failed to start the engine")
              }
          }
          
          // Start the haptic engine for the first time.
          do {
              try self.engine.start()
          } catch {
              print("Failed to start the engine: \(error)")
          }
      }
    func createContinuousHapticPlayer() {
        // Create an intensity parameter:
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                               value: initialIntensity)
        
        // Create a sharpness parameter:
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                               value: initialSharpness)
        
        // Create a continuous event with a long duration from the parameters.
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous,
                                            parameters: [intensity, sharpness],
                                            relativeTime: 0,
                                            duration: 100)
        
        do {
            // Create a pattern from the continuous haptic event.
            let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
            
            // Create a player from the continuous haptic pattern.
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            
            
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
        
    }
    
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
        
        // Setup haptic player when view appears
        createAndStartHapticEngine()
        createContinuousHapticPlayer()
    }
//    private var isContinuousHapticStarted = false
    private var isHapticStarted = false
    fileprivate func startContinuosPlayerEngine() {
        do {
            // Begin playing continuous pattern.
            try continuousPlayer.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Error starting the continuous haptic player: \(error)")
        }
    }
    let hapticDict = [
            CHHapticPattern.Key.pattern: [
                [CHHapticPattern.Key.event: [
                    CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                    CHHapticPattern.Key.time: CHHapticTimeImmediate,
                    CHHapticPattern.Key.eventParameters: [
                        [CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticIntensity.rawValue,
                         CHHapticPattern.Key.parameterValue: 1.0],
                        [CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticSharpness.rawValue,
                         CHHapticPattern.Key.parameterValue: 1]
                    ],
                    CHHapticPattern.Key.eventDuration: 0.2
                ]]
            ]
        ]

    
    func singleTapHaptic(onCompleted : @escaping () -> Void) {
        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
            engine.notifyWhenPlayersFinished { error in
                onCompleted()
                return .leaveEngineRunning
            }
        }
        catch{
            onCompleted()
            print("HAPTIC ENGINE ERROR")
        }
    }
    func onDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        isDragging = true
        fingerDotModel.position = constrainPosition(value.location, in: geometry.size, dotSize: fingerDotModel.size)

        if !isHapticStarted {
            isHapticStarted = true
            singleTapHaptic{
                if self.isDragging {
                    self.startContinuosPlayerEngine()
                }
                
            }
           
            withAnimation(.easeOut(duration: 0.6)) {
                self.rippleScale = 1.0 // Ripple expands
                self.rippleOpacity = 0.0 // Ripple fades out
            } completion: {
                self.rippleOpacity = 1
                self.rippleScale = 0
            }
        }
        let distance = calculateDistance(from: fingerDotModel.position, to: randomDotModel.position)
        if distance < fingerDotModel.size {
            updateRandomDotModel(in: geometry.size, dotSize: randomDotModel.size)
        }
        else if distance < MAX_DISTANCE {
            let intensity : Float = Float(1.0 - (distance / MAX_DISTANCE))
            print("INTENSITY ", intensity)
            backgroundFlickerIntensity = CGFloat(intensity)
            
            if hasHepticEngineSupport {
                // Create dynamic parameters for the updated intensity & sharpness.
                           let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                                             value: intensity,
                                                                             relativeTime: 0)
                           
                           let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                                             value: intensity,
                                                                             relativeTime: 0)
                           
                           // Send dynamic parameters to the haptic player.
                           do {
                               try continuousPlayer.sendParameters([intensityParameter, sharpnessParameter],
                                                                   atTime: 0)
                           } catch let error {
                               print("Dynamic Parameter Error: \(error)")
                           }
                
            } else {
                withAnimation(.easeInOut(duration: 0.1).repeatForever()) {
                    opacity = opacity > 0 ? 0 : 1
                }
            }
        } else {
            backgroundFlickerIntensity = 0
            // Set intensity to zero when out of range
//            if hasHepticEngineSupport {
//                do {
//                    intensityParameter = CHHapticDynamicParameter(
//                        parameterID: .hapticIntensityControl,
//                        value: 0,
//                        relativeTime: 0
//                    )
//                    try hapticPlayer?.sendParameters([intensityParameter!],
//                                                   atTime: CHHapticTimeImmediate)
//                } catch {
//                    print("Haptic update error: \(error)")
//                }
//            }
        }
    }

    func onDragEnded() {
        isHapticStarted = false
        isDragging = false
        cleanup() // Stop haptic feedback when drag ends
    }
    
    func cleanup() {
        do {
                           try continuousPlayer.stop(atTime: CHHapticTimeImmediate)
                       } catch let error {
                           print("Error stopping the continuous haptic player: \(error)")
                       }
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
  
    private var hasHepticEngineSupport: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private func randomPosition(in size: CGSize, dotSize: CGFloat) -> CGPoint {
        let xRange = dotSize/2...size.width-dotSize/2
        let yRange = dotSize/2...size.height-dotSize/2
        return CGPoint(x: CGFloat.random(in: xRange),
                       y: CGFloat.random(in: yRange))
    }
}
