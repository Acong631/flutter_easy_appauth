import 'package:flutter/services.dart';


import 'authorization_request.dart';
import 'authorization_response.dart';

class FlutterEasyAppauth {
  static final FlutterEasyAppauth _easyAppauth = FlutterEasyAppauth._interal();

  factory FlutterEasyAppauth(){
    return _easyAppauth;
  }
  FlutterEasyAppauth._interal();

  static const MethodChannel _channel =
  const MethodChannel('flutter_easy_appauth');

  Future<AuthorizationResponse>authorizeAndExchangeCode(AuthorizationRequest request) async{
    Map result = await _channel.invokeMethod('authorizeAndExchangeCode',request.toMap());
    return AuthorizationResponse.initAuthorizationResponse(result);
  }
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}