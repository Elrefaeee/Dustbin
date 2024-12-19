import 'package:flutter/material.dart';
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrackDustbinPage()),
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
