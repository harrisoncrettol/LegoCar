# Lego Car BLE Rover

<p align="center">
  <img src="lego_car_demo.gif" alt="Lego Car controlled by iPad" />
</p>

## Overview
A custom-built, Bluetooth-controlled Lego rover. This project gives life to a 20-year-old Lego chassis using an ESP32-C3 microcontroller, a stepper motor, and a custom iOS app built with SwiftUI and CoreBluetooth.

## Hardware Components
* **Microcontroller:** ESP32-C3 Super Mini
* **Motor:** 28BYJ-48 Stepper Motor
* **Motor Driver:** ULN2003 Driver Board
* **Power:** 5V LiPo Battery (with TP4056 charge controller)
* **Chassis:** Custom Lego build utilizing a Technic axle for direct motor integration
* **Extras:** LEDs for toggleable headlights

## Software Stack
* **Firmware:** C++ (Arduino IDE) running a custom BLE Server and non-blocking stepper control logic.
* **iOS App:** Swift & SwiftUI utilizing CoreBluetooth for real-time remote control.

## Getting Started
1. **Hardware:** Wire the ESP32 to the ULN2003 driver (Pins 5, 6, 7, 10 to IN1, IN2, IN3, IN4). Ensure a common ground and share the 5V power line from the LiPo battery.
2. **Firmware:** Flash `LegoCarEsp32.ino` to your ESP32-C3 using the Arduino IDE.
3. **Software:** Open the iOS project in Xcode, build, and deploy to your iPhone or iPad.
4. **Drive:** Power on the car, launch the app, let it connect, and drive!
