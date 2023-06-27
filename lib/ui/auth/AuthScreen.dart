import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:emartdriver/ui/login/LoginScreen.dart';
import 'package:emartdriver/ui/signUp/SignUpScreen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              // color: Colors.purple,
              fit: BoxFit.cover,
              width: 150,
              height: 150,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 32, right: 16, bottom: 8),
            child: Text(
              'Welcome to eMart Driver'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.purple, fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Text(
              'Make extra cash by delivery orders to our customers.'.tr(),
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    side: BorderSide(
                      color: Colors.purple,
                    ),
                  ),
                ),
                child: Text(
                  'Log In'.tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  push(context, LoginScreen());
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 20, bottom: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    side: BorderSide(
                      color: Colors.purple,
                    ),
                  ),
                ),
                child: Text(
                  'Sign Up'.tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                onPressed: () {
                  push(context, SignUpScreen());
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
