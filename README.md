# Haptic Engine Project

## Overview

This project demonstrates a dynamic haptic feedback system based on the proximity of a finger to a randomly placed dot on the screen. The closer the user's finger gets to the dot, the more intense the haptic vibration feedback becomes. This project is built to showcase haptic feedback integration with a touch interface.

![Image 1](Screenshot 2024-11-18 at 4.36.42 PM.png)
![Image 2](Screenshot 2024-11-18 at 4.36.47 PM.png)
![Image 3](Screenshot 2024-11-18 at 4.36.52 PM.png)


## Features

- **Random Dot Placement**: A dot appears at a random location on the screen.
- **Haptic Feedback**: As the user drags their finger near the dot, the intensity of the haptic feedback increases according to the distance from the dot.
- **Dynamic Feedback**: The haptic feedback intensity is continuously updated as the user moves their finger closer or farther away from the dot.

## How It Works

1. **Dot Placement**: A dot is randomly placed at a location within the screen.
2. **Distance Calculation**: As the user moves their finger, the distance between the finger and the dot is calculated in real time.
3. **Haptic Vibration**: Based on the distance, the intensity of the haptic vibration is adjusted, creating a feedback loop. The closer the finger gets, the stronger the vibration.
4. **Feedback Control**: The haptic feedback response is powered by the device's built-in haptic engine, utilizing both standard and custom vibration patterns.

## Technologies Used

- **Haptic Feedback**: Integrated with the device’s native haptic engine to provide dynamic tactile feedback.
- **Touch Interface**: Using touch gesture recognition to detect the position of the user’s finger on the screen.
- **SwiftUI**: Leveraging SwiftUI to create a responsive and interactive UI.


## Installation

To run this project locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/ShahzaibAli02/HepticEngine.git
