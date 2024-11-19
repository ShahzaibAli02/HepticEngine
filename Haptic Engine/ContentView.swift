import SwiftUI

struct HapticTrackingView: View {
    @StateObject private var viewModel = HapticTrackingViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                
                
                Color.clear
                    .contentShape(Rectangle())
                    .background(
                        Rectangle()
                            .fill(viewModel.backgroundFlickerIntensity > 0.5 ? Color.green.opacity(viewModel.opacity) : Color.red.opacity(viewModel.opacity))
                            .edgesIgnoringSafeArea(.all)
                    )
                
                Circle().stroke(Color.blue, lineWidth: 3) // Customize stroke color and width
                    .scaleEffect(viewModel.rippleScale)
                    .opacity(viewModel.rippleOpacity)
                    .position(viewModel.fingerDotModel.position)
                    .frame(width: geometry.size.width, height:  geometry.size.height) // Adjust the maximum size of the ripple
                  
                        
                        Circle()
                            .fill(viewModel.randomDotModel.color)
                            .frame(width: viewModel.randomDotModel.size, height: viewModel.randomDotModel.size)
                            .position(viewModel.randomDotModel.position)
                        
                        
                        Circle()
                            .fill(viewModel.fingerDotModel.color)
                            .frame(width: viewModel.fingerDotModel.size, height: viewModel.fingerDotModel.size)
                            .position(viewModel.fingerDotModel.position)
                            .opacity(viewModel.isDragging ? 1 : 0)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                viewModel.onDragChanged(value, in: geometry)
                            }
                            .onEnded { _ in
                                viewModel.onDragEnded()
                            }
                    )
                    .onAppear {
                        viewModel.onAppear(in: geometry)
                    }
            }
        }
    }

struct HapticTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        HapticTrackingView()
    }
}
