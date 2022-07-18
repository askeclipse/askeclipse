import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart';
import '../../../screens/login_sms/login_sms_screen.dart';
import '../../../screens/login_sms/verify.dart';
import '../../../services/services.dart';
import '../services/index.dart';

class DigitsMobileLoginScreen extends LoginSMSScreen {
  const DigitsMobileLoginScreen();

  @override
  LoginSMSScreenState<DigitsMobileLoginScreen> createState() =>
      _LoginSMSState();
}

class _LoginSMSState extends LoginSMSScreenState<DigitsMobileLoginScreen> {
  final _services = DigitsMobileLoginServices();

  @override
  Future<void> loginSMS(context) async {
    if (phoneNumber == null) {
      Tools.showSnackBar(
          ScaffoldMessenger.of(context), S.of(context).pleaseInput);
    } else {
      await playAnimation();
      try {
        await _services.loginCheck(
            countryCode: countryCode?.dialCode,
            mobile: phoneNumber?.replaceAll(countryCode!.dialCode!, ''));

        Future autoRetrieve(String verId) {
          return stopAnimation();
        }

        Future smsCodeSent(String verId, [int? forceCodeResend]) {
          stopAnimation();
          return Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCode(
                verId: verId,
                phoneNumber: phoneNumber,
                verifySuccessStream: verifySuccessStream.stream,
                resendToken: forceCodeResend,
                callback: _submitLogin,
              ),
            ),
          );
        }

        final verifiedSuccess = verifySuccessStream.add;

        void verifyFailed(exception) {
          stopAnimation();
          failMessage(exception.message, context);
        }

        Services().firebase.verifyPhoneNumber(
              phoneNumber: phoneNumber!,
              codeAutoRetrievalTimeout: autoRetrieve,
              codeSent: smsCodeSent,
              verificationCompleted: verifiedSuccess,
              verificationFailed: verifyFailed,
            );
      } catch (e) {
        await stopAnimation();
        failMessage(e.toString(), context);
      }
    }
  }

  Future<void> _submitLogin(String smsCode, firebase_auth.User user) async {
    try {
      await playAnimation();
      final fToken = await user.getIdToken();
      var loggedInUser = await _services.login(
          otp: smsCode,
          countryCode: countryCode?.dialCode,
          mobile: phoneNumber?.replaceAll(countryCode!.dialCode!, ''),
          fToken: fToken);
      await Provider.of<UserModel>(context, listen: false)
          .setUser(loggedInUser);
      await stopAnimation();
      NavigateTools.navigateAfterLogin(loggedInUser, context);
    } catch (e) {
      await stopAnimation();
      failMessage(e.toString(), context);
    }
  }
}
