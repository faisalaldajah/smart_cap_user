// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:smart_cap_user/widgets/GradientButton.dart';
import 'package:smart_cap_user/widgets/TaxiButton.dart';

class LocationPin extends StatelessWidget {
  LocationPin({
    Key? key,
    required this.pinStatus,
    required this.onPressed,
    required this.onPressedDestination,
  }) : super(key: key);
  String pinStatus;
  VoidCallback onPressed;
  VoidCallback onPressedDestination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        const Text('Set your Location'),
        const SizedBox(height: 20),
        Image.asset('images/desticon.png'),
        const SizedBox(height: 20),
        //TODO
        (pinStatus == 'direction location')
            ? GradientButton(
                title: 'Destination',
                onPressed: onPressedDestination,
              )
            : TaxiButton(title: 'Pickup', onPressed: onPressed),
      ],
    );
  }
}
