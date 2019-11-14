
import 'package:flutter/cupertino.dart';

class AuthorizationResponse{

  String errorCode;
  String message;
  String accessToken;
  String refreshToken;
  DateTime accessTokenExpirationDateTime;
  String idToken;
  String tokenType;
  Map<String, dynamic> tokenAdditionalParameters;


  static AuthorizationResponse initAuthorizationResponse(Map result){
    AuthorizationResponse response = AuthorizationResponse();
    response.errorCode = result["error"];
    response.message = result["message"];

    if(result["error"] != "0"){
      return response;
    }


    Map responseDic = result["response"];

    response.accessToken = responseDic['accessToken'];
    response.refreshToken = responseDic['refreshToken'];
    response.accessTokenExpirationDateTime = responseDic['accessTokenExpirationTime'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
        responseDic['accessTokenExpirationTime'].toInt());
    response.idToken = responseDic['idToken'];
    response.tokenType = responseDic['tokenType'];
    response.tokenAdditionalParameters = responseDic['tokenAdditionalParameters']?.cast<String, dynamic>();
    return response;
  }
}