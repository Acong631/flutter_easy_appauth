import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_easy_appauth/flutter_easy_appauth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    AuthorizationResponse resonne;
    FlutterEasyAppauth appAuth = FlutterEasyAppauth();
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {

      resonne = await appAuth.authorizeAndExchangeCode(AuthorizationRequest(
        clientId:"@!CADB.9C8E.1925.560E!0001!982E.D9EC!0008!25B4.297D.BA9E.14E8",
        clientSecret:"83e8f617-a784-4116-99ff-135436d9b71b",
        issuer:"https://svs.chinavacc.com.cn",
        discoveryUrl:"https://svs.chinavacc.com.cn/.well-known/openid-configuration",
        redirectUrl:"io.identityserver.demo:/oauthredirect",
        scopes:['openid', 'profile', 'email',],
        serviceConfig:ServiceConfig("https://svs.chinavacc.com.cn/oxauth/restv1/authorize",
          "https://svs.chinavacc.com.cn/oxauth/restv1/token"),
        allowInsecureConnections: true

      ));
      debugPrint(resonne.toString());
    } on PlatformException {

    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = resonne.accessToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child:GestureDetector(
            onTap: initPlatformState,
            child: Text('Running on: $_platformVersion\n'),
          )//Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
