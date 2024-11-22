import 'package:flutter/material.dart';
import '../resources/AppText.dart';
import '../resources/appColor.dart';

class ControlDustbinPage extends StatelessWidget {
  const ControlDustbinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appColor.mainColor,
        title: Text('Control Dustbins', style: AppText.mainText),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // White back arrow icon
          onPressed: () {
            Navigator.pop(context); // Pop back to the main screen
          },
        ),
      ),
      body: Center(
        child: Text(
          'Controlling Dustbins...',
        ),
      ),
    );
  }
}