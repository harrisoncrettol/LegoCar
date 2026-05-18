// LegoCarEsp32.ino
#include <Stepper.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Hardware Setup
const int stepsPerRevolution = 2048;
const int IN1 = 5;
const int IN2 = 6;
const int IN3 = 7;
const int IN4 = 10;
const int LED_PIN = 4;

// IN2 and IN3 swapped for ULN2003 sequence
Stepper myStepper(stepsPerRevolution, IN1, IN3, IN2, IN4);

// Globals
int driveState = 0; 
int currentRPM = 10;
bool deviceConnected = false; 

// BLE UUIDs
#define SERVICE_UUID           "19B10000-E8F2-537E-4F6C-D104768A1214"
#define DRIVE_CHAR_UUID        "19B10001-E8F2-537E-4F6C-D104768A1214"
#define SPEED_CHAR_UUID        "19B10002-E8F2-537E-4F6C-D104768A1214"
#define HEADLIGHT_CHAR_UUID    "19B10003-E8F2-537E-4F6C-D104768A1214"

// Server Callbacks
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("SUCCESS: Device Connected!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("WARNING: Device Disconnected!");
      BLEDevice::startAdvertising();
      Serial.println("Waiting for a connection again...");
    }
};

// Characteristic Callbacks
class DriveCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      uint8_t* rxData = pCharacteristic->getData();
      size_t rxLength = pCharacteristic->getLength();
      if (rxLength > 0) {
        uint8_t cmd = rxData[0];
        if (cmd == 1) {
          driveState = 1;
          Serial.println("Command: Drive Forward");
        } else if (cmd == 2) {
          driveState = 2;
          Serial.println("Command: Drive Backward");
        } else {
          driveState = 0;
          Serial.println("Command: STOP");
        }
      }
    }
};

class SpeedCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      uint8_t* rxData = pCharacteristic->getData();
      size_t rxLength = pCharacteristic->getLength();
      if (rxLength > 0) {
        uint8_t rpm = rxData[0];
        if (rpm > 0 && rpm <= 15) { 
          currentRPM = rpm;
          myStepper.setSpeed(currentRPM);
          Serial.print("Command: Speed changed to ");
          Serial.print(currentRPM);
          Serial.println(" RPM");
        }
      }
    }
};

class HeadlightCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      uint8_t* rxData = pCharacteristic->getData();
      size_t rxLength = pCharacteristic->getLength();
      if (rxLength > 0) {
        uint8_t cmd = rxData[0];
        if (cmd == 1) {
          digitalWrite(LED_PIN, HIGH);
          Serial.println("Command: Headlights ON");
        } else {
          digitalWrite(LED_PIN, LOW);
          Serial.println("Command: Headlights OFF");
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  delay(3000); 
  Serial.println("\n--- ESP32 Stepper Rover Booting Up ---");

  pinMode(LED_PIN, OUTPUT);
  myStepper.setSpeed(currentRPM);

  Serial.println("Starting BLE Server...");
  BLEDevice::init("LegoCar_ESP32"); 
  
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // PROPERTY_READ required for iOS compatibility
  BLECharacteristic *pDriveCharacteristic = pService->createCharacteristic(
                                         DRIVE_CHAR_UUID,
                                         BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
                                       );
  pDriveCharacteristic->setCallbacks(new DriveCallbacks());

  BLECharacteristic *pSpeedCharacteristic = pService->createCharacteristic(
                                         SPEED_CHAR_UUID,
                                         BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
                                       );
  pSpeedCharacteristic->setCallbacks(new SpeedCallbacks());

  BLECharacteristic *pHeadlightCharacteristic = pService->createCharacteristic(
                                         HEADLIGHT_CHAR_UUID,
                                         BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
                                       );
  pHeadlightCharacteristic->setCallbacks(new HeadlightCallbacks());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  
  // iOS connection intervals
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);

  pAdvertising->start();
  Serial.println("Bluetooth is active! Connect your iOS app.");
}

void loop() {
  // Non-blocking motor steps
  if (driveState == 1) {
    myStepper.step(-1); // Forward
  } else if (driveState == 2) {
    myStepper.step(1);  // Backward
  } else {
    // Turn off coils to prevent overheating
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
    delay(1); 
  }
}