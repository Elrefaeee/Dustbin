import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../resources/AppText.dart';
import '../resources/appColor.dart';
import 'ControlDustbinPage.dart';

class TrackDustbinPage extends StatefulWidget {
  final MqttServerClient client;

  const TrackDustbinPage({Key? key, required this.client}) : super(key: key);

  @override
  State<TrackDustbinPage> createState() => _TrackDustbinPageState();
}

class _TrackDustbinPageState extends State<TrackDustbinPage> {
  List<Map<String, dynamic>> dustbins = [];
  int counter = 1; // Used to generate unique dustbin names
  Timer? connectionMonitorTimer;

  @override
  void initState() {
    super.initState();
    connectionMonitorTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _monitorConnection();
    });
  }

  @override
  void dispose() {
    connectionMonitorTimer?.cancel();
    super.dispose();
  }

  void _addDustbin() {
    setState(() {
      String dustbinName = 'Dustbin$counter';
      dustbins.add({
        'name': dustbinName,
        'isConnected': false,
        'statusTopic': '$dustbinName/status',
        'commandTopic': '$dustbinName/command',
      });
      _connectDustbin(dustbinName);
      counter++;
    });
  }

  Future<void> _connectDustbin(String dustbinName) async {
    try {
      // Ensure the MQTT client is connected
      if (widget.client.connectionStatus?.state != MqttConnectionState.connected) {
        await widget.client.connect('Networkbin', 'Networkbin123'); // Replace with your credentials
      }

      // Get the topics for the specific dustbin
      String statusTopic = '$dustbinName/status';
      String commandTopic = '$dustbinName/command';

      // Subscribe to the status and command topics
      widget.client.subscribe(statusTopic, MqttQos.atMostOnce);
      widget.client.subscribe(commandTopic, MqttQos.atMostOnce);

      // Listen for messages on the topics
      widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
        final String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final String receivedTopic = messages[0].topic;

        // Handle connection status updates
        if (receivedTopic == statusTopic && payload == 'connected') {
          setState(() {
            int index = dustbins.indexWhere((d) => d['name'] == dustbinName);
            if (index != -1) {
              dustbins[index]['isConnected'] = true;
            }
          });
        }

        // Handle other command-related messages here
        if (receivedTopic == commandTopic) {
          print('Command received for $dustbinName: $payload');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting to $dustbinName...')),
      );
    } catch (e) {
      print('Error connecting to $dustbinName: $e');
      _handleConnectionFailure(dustbinName);
    }
  }

  void _handleConnectionFailure(String dustbinName) {
    setState(() {
      int index = dustbins.indexWhere((d) => d['name'] == dustbinName);
      if (index != -1) {
        dustbins[index]['isConnected'] = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to connect to $dustbinName')),
    );
  }

  void _monitorConnection() {
    for (var dustbin in dustbins) {
      if (!dustbin['isConnected']) {
        _connectDustbin(dustbin['name']);
      }
    }
  }

  void _removeDustbin(int index) {
    setState(() {
      dustbins.removeAt(index);
    });
  }

  void _onDustbinTap(String dustbinName) {
    int index = dustbins.indexWhere((d) => d['name'] == dustbinName);
    if (index != -1 && dustbins[index]['isConnected']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlDustbinPage(
            title: dustbinName,
            client: widget.client,
            ultrasonicTopic: '$dustbinName/ultrasonic2', // Pass ultrasonic1 topic
          ),
        ),
      ).then((_) {
        _checkAndNotifyFullness(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$dustbinName is not connected')),
      );
    }
  }
  void _checkAndNotifyFullness(int index) {
    // Mock logic to simulate fullness percentage check
    // Replace this with actual values from dustbin data if available
    double fullness = dustbins[index]['fullness'] ?? 0.0;

    if (fullness >= 0.8 && fullness < 1.0) {
      _showNotification("About to Fill", "The dustbin '${dustbins[index]['name']}' is 80% full.");
    } else if (fullness >= 1.0) {
      _showNotification("Fill", "The dustbin '${dustbins[index]['name']}' is 100% full.");
    }
  }

  void _showNotification(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title: $message"),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appColor.mainColor,
        title: Text('Track Dustbins', style: AppText.mainText),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: dustbins.length,
            itemBuilder: (context, index) {
              String dustbinName = dustbins[index]['name'];
              bool isConnected = dustbins[index]['isConnected'];
              return InkWell(
                onTap: () => _onDustbinTap(dustbinName),
                child: ListTile(
                  title: Text(
                    dustbinName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  subtitle: Text(
                    "Status: ${isConnected ? 'Connected' : 'Not Connected'}",
                    style: TextStyle(color: isConnected ? Colors.green : Colors.red),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeDustbin(index),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDustbin,
        child: const Icon(Icons.add),
        backgroundColor: appColor.mainColor,
      ),
    );
  }
}
