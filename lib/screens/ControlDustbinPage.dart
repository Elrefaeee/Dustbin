import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../resources/AppText.dart';
import '../resources/appColor.dart';

class ControlDustbinPage extends StatefulWidget {
  final String title;
  final MqttServerClient client;
  final String ultrasonicTopic;

  ControlDustbinPage({
    super.key,
    required this.title,
    required this.client,
    required this.ultrasonicTopic,
  });

  @override
  State<ControlDustbinPage> createState() => _ControlDustbinPageState();
}

class _ControlDustbinPageState extends State<ControlDustbinPage> {
  double fullness = 0.0; // Fullness level (0.0 - 1.0)
  bool isDustbinOpen = false; // Indicates whether the dustbin is open
  String lastNotification = ""; // Tracks the last notification state
  late Timer reconnectTimer;

  @override
  void initState() {
    super.initState();
    _ensureConnected();
    _subscribeToUltrasonicTopic();
  }

  @override
  void dispose() {
    reconnectTimer.cancel();
    super.dispose();
  }

  Future<void> _ensureConnected() async {
    reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (widget.client.connectionStatus?.state != MqttConnectionState.connected) {
        try {
          await widget.client.connect();
        } catch (e) {
          // Handle reconnection failure silently
        }
      }
    });
  }

  void _subscribeToUltrasonicTopic() {
    if (widget.client.connectionStatus?.state == MqttConnectionState.connected) {
      widget.client.subscribe(widget.ultrasonicTopic, MqttQos.atMostOnce);

      widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var message in messages) {
          final MqttPublishMessage recMessage = message.payload as MqttPublishMessage;
          final String payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

          if (message.topic == widget.ultrasonicTopic && !isDustbinOpen) {
            // Update fullness only if the dustbin is not open
            _updateFullnessFromUltrasonic(payload);
          }
        }
      });
    }
  }

  void _updateFullnessFromUltrasonic(String distanceString) {
    try {
      final distance = double.tryParse(distanceString);

      if (distance != null) {
        if (distance > 20) {
          // Distance > 20 cm means empty
          setState(() {
            fullness = 0.0;
          });
        } else if (distance <= 20 && distance > 15) {
          // Between 15 and 20 cm -> 20%
          setState(() {
            fullness = 0.2;
          });
        } else if (distance <= 15 && distance > 10) {
          // Between 10 and 15 cm -> 40%
          setState(() {
            fullness = 0.4;
          });
        } else if (distance <= 10 && distance > 7) {
          // Between 10 and 7 cm -> 60%
          setState(() {
            fullness = 0.6;
          });
        } else if (distance <= 7 && distance > 5) {
          // Between 7 and 5 cm -> 80%
          setState(() {
            fullness = 0.8;
          });
          _sendNotification("About to Fill", "The dustbin is 80% full.");
        } else if (distance <= 5 && distance >= 0) {
          // Between 0 and 5 cm -> 100%
          setState(() {
            fullness = 1.0;
          });
          _sendNotification("Fill", "The dustbin is 100% full.");
        }
      }
    } catch (e) {
      // Handle parsing errors silently
    }
  }

  void _sendNotification(String title, String message) {
    if (lastNotification != title) {
      lastNotification = title; // Update the last notification state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title: $message"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _publishMessage(String command) {
    if (widget.client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);

      widget.client.publishMessage(
        widget.ultrasonicTopic.replaceFirst('ultrasonic2', 'command'), // Replace topic
        MqttQos.atMostOnce,
        builder.payload!,
      );

      // Update dustbin state based on the command
      setState(() {
        if (command == "open") {
          isDustbinOpen = true; // Freeze the percentage when opened
        } else if (command == "close") {
          isDustbinOpen = false; // Allow updates when closed
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appColor.mainColor,
        title: Text('Control ${widget.title}', style: AppText.mainText),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 100,
                  height: 200,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 3),
                      right: BorderSide(color: Colors.black, width: 3),
                      bottom: BorderSide(color: Colors.black, width: 3),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  width: 94,
                  height: 200 * fullness,
                  color: Colors.green.withOpacity(0.7),
                ),
                Positioned(
                  bottom: 10,
                  child: Text(
                    '${(fullness * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _publishMessage("open");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Open Dustbin'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _publishMessage("close");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Close Dustbin'),
            ),
          ],
        ),
      ),
    );
  }
}

