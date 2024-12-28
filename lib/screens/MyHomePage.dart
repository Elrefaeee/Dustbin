import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../resources/appColor.dart';
import '../resources/AppText.dart';
import '../widgets/CustomCardWidget.dart';
import 'TrackDustbinPage.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    client = MqttServerClient.withPort(
      'a1358be4c1af4257996db77815527e1d.s1.eu.hivemq.cloud', // Replace with your HiveMQ broker URL
      'TrashBinClients', // Replace with a unique client ID
      8883,
    );
    client.secure = true;
    client.keepAlivePeriod = 90;
  }

  Future<void> _connectToMqtt() async {
    try {
      await client.connect('Networkbin', 'Networkbin123'); // Replace with credentials
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('Connected to MQTT broker');
      } else {
        print('Failed to connect to MQTT broker');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appColor.mainColor,
        title: Text(
          widget.title,
          style: AppText.mainText,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          // center Y-Axis
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ============dustbin image================
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Image.asset(
                'images/logo.png',
                width: 550,
              ),
            ),
            // ==========================================
            const SizedBox(height: 50),
            //============Track Dustbin Button============
            CustomCardButton(
              buttonText: 'Track Dustbins',
              onTap: () async {
                await _connectToMqtt();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrackDustbinPage(client: client)),
                );
              },
            ),

            // ==========================================
          ],
        ),
      ),
    );
  }
}
