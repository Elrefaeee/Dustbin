import 'package:flutter/material.dart';
import '../resources/AppText.dart';
import '../resources/appColor.dart';

class CustomCardButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onTap; // Callback for the button press

  CustomCardButton({super.key, required this.buttonText, required this.onTap});

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
          splashColor: Colors.white.withOpacity(0.3),
          // Splash effect on tap
          borderRadius: BorderRadius.circular(10),
          // Matching radius with card's corners
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
