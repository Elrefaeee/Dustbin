import 'package:flutter/material.dart';

import '../resources/appColor.dart';
import '../resources/AppText.dart';
import 'ControlDustbinPage.dart';
import 'TrackDustbinPage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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
            _CustomCardButton(
              buttonText: 'Track Dustbins',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrackDustbinPage()),
                );
              },
            ),
            // ==========================================
            const SizedBox(height: 20), // Space between cards
            //============Control Dustbin Button============
            _CustomCardButton(
              buttonText: 'Control Dustbins',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ControlDustbinPage()),
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

class _CustomCardButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onTap; // Callback for the button press

  const _CustomCardButton({super.key, required this.buttonText, required this.onTap});

  @override
  //============Widget function for each button============
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        color: appColor.mainColor,
        elevation: 5, // Shadow effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.3), // Splash effect on tap
          borderRadius: BorderRadius.circular(10), // Matching radius with card's corners
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Text(
              buttonText,
              style: AppText.mainText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
