import 'package:flutter/material.dart';
import 'package:smart_cap_user/Utilities/Constants/AppColors.dart';
import 'package:smart_cap_user/globalvariable.dart';
import 'package:smart_cap_user/screens/mainPage/main_page_controller.dart';
import 'package:smart_cap_user/styles/styles.dart';
import 'package:smart_cap_user/widgets/BrandDivier.dart';

class TheDrawer extends StatelessWidget {
  const TheDrawer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final MainPageController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          Container(
            color: Colors.white,
            height: 160,
            child: DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    'images/user_icon.png',
                    height: 60,
                    width: 60,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        currentUserInfo!.fullname!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Brand-Bold',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          BrandDivider(),
          const SizedBox(
            height: 10,
          ),
          ListTile(
            leading: const Icon(
              Icons.card_giftcard,
              color: AppColors.primary,
            ),
            title: Text(
              'Free Rides',
              style: kDrawerItemStyle,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.credit_card,
              color: AppColors.primary,
            ),
            title: Text(
              'Payments',
              style: kDrawerItemStyle,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.history,
              color: AppColors.primary,
            ),
            title: Text(
              'Ride History',
              style: kDrawerItemStyle,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.contact_support,
              color: AppColors.primary,
            ),
            title: Text(
              'Support',
              style: kDrawerItemStyle,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.info,
              color: AppColors.primary,
            ),
            title: Text(
              'About',
              style: kDrawerItemStyle,
            ),
          ),
          ListTile(
            onTap: controller.signOut,
            leading: const Icon(
              Icons.contact_support,
              color: AppColors.primary,
            ),
            title: Text(
              'Logout',
              style: kDrawerItemStyle,
            ),
          ),
        ],
      ),
    );
  }
}
