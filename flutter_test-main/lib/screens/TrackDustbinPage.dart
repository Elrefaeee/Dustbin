import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import '../resources/AppText.dart';
import '../resources/appColor.dart';
import 'ControlDustbinPage.dart';

class TrackDustbinPage extends StatefulWidget {
  const TrackDustbinPage({Key? key}) : super(key: key);

  @override
  State<TrackDustbinPage> createState() => _TrackDustbinPageState();
}

class _TrackDustbinPageState extends State<TrackDustbinPage> {
  List<String> dustbins = [];
  int counter = 1;
  Map<String, bool> dustbinConnectionStatus = {};
  late MqttServerClient client;
  Timer? connectionMonitorTimer;
  bool isLoading = false;
  bool _isMounted = false;


  @override
  void initState() {
    super.initState();
    _isMounted = true;
    client = MqttServerClient.withPort(
      'a1358be4c1af4257996db77815527e1d.s1.eu.hivemq.cloud', // Replace with your HiveMQ broker URL
      'TrashBinClients', // Replace with a unique client ID
      8883,
    );

    _initializeMqttClient();

    connectionMonitorTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _monitorConnection();
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    connectionMonitorTimer?.cancel();
    client.disconnect();
    super.dispose();
  }

  void _initializeMqttClient() {
    client.secure = true;
    client.keepAlivePeriod = 90;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;

    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
  }

  Future<void> _connectMqtt() async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Already connected to the broker');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await client.connect('Networkbin', 'Networkbin123'); // Replace with your credentials
      setState(() {
        isLoading = false;
      });

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('Successfully connected to the broker');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to the MQTT broker')),
        );
      } else {
        _showErrorSnackbar('Connection failed');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to connect: $e');
    }
  }

  void _monitorConnection() {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('Connection lost. Reconnecting...');
      _connectMqtt();
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
    setState(() {
      for (var dustbin in dustbins) {
        dustbinConnectionStatus[dustbin] = true;
      }
    });
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    if (_isMounted) {
    setState(() {
      for (var dustbin in dustbins) {
        dustbinConnectionStatus[dustbin] = false;
      }
    });
    }
  }

  void _addDustbin() {
    setState(() {
      String newDustbin = 'Dustbin $counter';
      dustbins.add(newDustbin);
      dustbinConnectionStatus[newDustbin] = false;
      counter++;
    });
  }

  void _removeDustbin(int index) {
    setState(() {
      dustbinConnectionStatus.remove(dustbins[index]);
      dustbins.removeAt(index);
    });
  }

  void _onDustbinTap(String dustbin) {
    bool isConnected = dustbinConnectionStatus[dustbin] ?? false;

    if (isConnected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlDustbinPage(
            title: dustbin,
            client: client,
          ),
        ),
      );
    } else {
      _connectDustbin(dustbin);
    }
  }

  Future<void> _connectDustbin(String dustbin) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _connectMqtt();
      bool isConnected = client.connectionStatus?.state == MqttConnectionState.connected;

      setState(() {
        isLoading = false;
        dustbinConnectionStatus[dustbin] = isConnected;
      });

      String message = isConnected ? 'Connected to $dustbin' : 'Failed to connect to $dustbin';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

      if (isConnected) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ControlDustbinPage(
              title: dustbin,
              client: client,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to connect to $dustbin');
    }
  }

  void _showErrorSnackbar(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              String dustbin = dustbins[index];
              bool isConnected = dustbinConnectionStatus[dustbin] ?? false;
              return InkWell(
                onTap: () => _onDustbinTap(dustbin),
                child: ListTile(
                  title: Text(
                    dustbin,
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
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
