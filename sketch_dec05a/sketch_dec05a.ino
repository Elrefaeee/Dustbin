#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <Servo.h>
#include <time.h>
#include <TZ.h>
#include <FS.h>
#include <LittleFS.h>
#include <CertStoreBearSSL.h>

// Wi-Fi credentials
const char* ssid = "Tarek";
const char* password = "3417102720";

// MQTT server details
const char* mqtt_server = "a1358be4c1af4257996db77815527e1d.s1.eu.hivemq.cloud";

// Dustbin details
int dustbinIndex = 1;
String dustbinID = "Dustbin" + String(dustbinIndex);

// MQTT topics
String mqtt_topic_status = dustbinID + "/status";
String mqtt_topic_command = dustbinID + "/command";
String mqtt_topic_ultrasonic1 = dustbinID + "/ultrasonic1";
String mqtt_topic_ultrasonic2 = dustbinID + "/ultrasonic2";

// MQTT client with secure connection
BearSSL::CertStore certStore;
BearSSL::WiFiClientSecure espClient;
PubSubClient client(espClient);

// Pins
const int trigPin1 = D7;
const int echoPin1 = D8;
const int trigPin2 = D3;
const int echoPin2 = D4;
const int servoPin = D5;
const int ledPin = D6;

// Servo
Servo servo;

// Variables
unsigned long lastServoMoveTime = 0;
const int servoMoveDelay = 2000; // 2 seconds
bool servoAt180 = false;
const int garbageFullThreshold = 5; // cm
bool garbageIsFull = false;
bool isTrashBinOpen = false; // Tracks if the trash bin is open

// Function to connect to Wi-Fi
void setup_wifi() {
  delay(10);
  Serial.print("Connecting to WiFi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

// Sync time for secure TLS
void setDateTime() {
  configTime(TZ_Europe_Berlin, "pool.ntp.org", "time.nist.gov");
  Serial.print("Waiting for NTP sync...");
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {
    delay(100);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println();
  struct tm timeinfo;
  gmtime_r(&now, &timeinfo);
  Serial.printf("Current time: %s\n", asctime(&timeinfo));
}

// MQTT callback function
void callback(char* topic, byte* payload, unsigned int length) {
  String receivedTopic = String(topic);
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println("Message arrived [" + receivedTopic + "]: " + message);

  if (receivedTopic == mqtt_topic_command) {
    if (message == "open") {
      servo.write(180); // Open the trash bin
      isTrashBinOpen = true; // Set flag
      digitalWrite(ledPin, HIGH);
      Serial.println("Trash bin opened");
    } else if (message == "close") {
      servo.write(0); // Close the trash bin
      isTrashBinOpen = false; // Reset flag
      digitalWrite(ledPin, LOW);
      Serial.println("Trash bin closed");
    }
  }
}

// Reconnect to MQTT broker
void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = dustbinID + "_Client";
    if (client.connect(clientId.c_str(), "Networkbin", "Networkbin123")) {
      Serial.println("Connected to MQTT broker");

      client.publish(mqtt_topic_status.c_str(), "connected");
      client.subscribe(mqtt_topic_command.c_str());
      Serial.println("Subscribed to: " + mqtt_topic_command);
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// Measure distance using ultrasonic sensors
int measureDistance(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);
  if (duration == 0) {
    return -1; 
  }
  return duration * 0.034 / 2;
}

// Handle garbage bin logic
void handleGarbageBinStatus() {
  int distance1 = measureDistance(trigPin1, echoPin1);
  int distance2 = measureDistance(trigPin2, echoPin2);

  garbageIsFull = distance2 > 0 && distance2 <= garbageFullThreshold;

  char distance1Str[10];
  char distance2Str[10];
  snprintf(distance1Str, sizeof(distance1Str), "%d", distance1);

  // Publish ultrasonic2 only if the trash bin is not open
  if (!isTrashBinOpen) {
    snprintf(distance2Str, sizeof(distance2Str), "%d", distance2);
    client.publish(mqtt_topic_ultrasonic2.c_str(), distance2Str);
  }

  client.publish(mqtt_topic_ultrasonic1.c_str(), distance1Str);

  if (!garbageIsFull && distance1 > 0 && distance1 <= 10) {
    servo.write(180);
    isTrashBinOpen = true; // Trash bin is now open
    servoAt180 = true;
    lastServoMoveTime = millis();
  } else if (servoAt180 && millis() - lastServoMoveTime > servoMoveDelay) {
    servo.write(0);
    isTrashBinOpen = false; // Trash bin is now closed
    servoAt180 = false;
  }

  if (garbageIsFull) {
    client.publish(mqtt_topic_status.c_str(), "FULL");
    digitalWrite(ledPin, HIGH);
  } else {
    client.publish(mqtt_topic_status.c_str(), "NOT FULL");
    digitalWrite(ledPin, LOW);
  }
}

void setup() {
  Serial.begin(115200);
  if (!LittleFS.begin()) {
    Serial.println("LittleFS Mount Failed");
    return;
  }

  int numCerts = certStore.initCertStore(LittleFS, PSTR("/certs.idx"), PSTR("/certs.ar"));
  if (numCerts == 0) {
    Serial.println("No certificates found. Upload them using LittleFS.");
    return;
  }

  pinMode(trigPin1, OUTPUT);
  pinMode(echoPin1, INPUT);
  pinMode(trigPin2, OUTPUT);
  pinMode(echoPin2, INPUT);
  pinMode(ledPin, OUTPUT);

  servo.attach(servoPin);
  servo.write(0);

  setup_wifi();
  setDateTime();

  espClient.setCertStore(&certStore);
  client.setServer(mqtt_server, 8883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  handleGarbageBinStatus();
}
