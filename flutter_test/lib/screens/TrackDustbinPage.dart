import 'package:flutter/material.dart';
import '../resources/AppText.dart';
import '../resources/appColor.dart';

class TrackDustbinPage extends StatelessWidget {
  const TrackDustbinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appColor.mainColor,
        title: Text('Track Dustbins', style: AppText.mainText),
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
          'Tracking Dustbins...',
        ),
      ),
    );
  }
}