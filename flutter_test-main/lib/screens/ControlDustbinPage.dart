import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../resources/AppText.dart';
import '../resources/appColor.dart';

class ControlDustbinPage extends StatefulWidget {
  final String title;
  final MqttServerClient client;

  ControlDustbinPage({super.key, required this.title, required this.client});

  @override
  State<ControlDustbinPage> createState() => _ControlDustbinPageState();
}

class _ControlDustbinPageState extends State<ControlDustbinPage> {
  double fullness = 0.0; // Initial trashcan fullness (20%)
  bool isOpening = false;
  bool isClosing = false;
  late Timer reconnectTimer;

  @override
  void initState() {
    super.initState();
    _ensureConnected();
    _subscribeToUltrasonicStatus();
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
          print('Reconnecting to MQTT broker...');
          await widget.client.connect();
        } catch (e) {
          print('Connection attempt failed: $e');
        }
      }
    });
  }

  void _subscribeToUltrasonicStatus() {
    const topic = 'ultrasonic2/status';
    if (widget.client.connectionStatus?.state == MqttConnectionState.connected) {
      widget.client.subscribe(topic, MqttQos.atMostOnce);

      widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMessage = messages[0].payload as MqttPublishMessage;
        final payload =
        MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

        if (isClosing) {
          _updateFullnessFromUltrasonic(payload);
        }
      });
    }
  }

  void _updateFullnessFromUltrasonic(String distanceString) {
    try {
      final distance = double.parse(distanceString); // Ultrasonic distance in cm
      if (distance >= 5 && distance <= 20) {
        // Scale the distance so that 5 cm is 0% and 20 cm is 75%
        final percentage = ((20 - distance) / 15).clamp(0.0, 1.0);

        // Make 75% = 100%
        final adjustedFullness = (percentage * 0.75).clamp(0.0, 1.0);

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            fullness = adjustedFullness;
          });
        }
      }
    } catch (e) {
      print('Error parsing ultrasonic distance: $e');
    }
  }



  void _publishMessage(String command) {
    if (widget.client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);

      widget.client.publishMessage(
        'trashbin/command', // Topic for controlling dustbin
        MqttQos.atMostOnce,
        builder.payload!,
      );

      print('Published command: $command'); // Debug log

      setState(() {
        if (command == "open") {
          isOpening = true;
          isClosing = false;
        } else if (command == "close") {
          isClosing = true;
          isOpening = false;
        }
      });
    } else {
      print('Cannot publish. Client not connected.');
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
                _publishMessage("open"); // Send "open" command
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
                _publishMessage("close"); // Send "close" command
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
