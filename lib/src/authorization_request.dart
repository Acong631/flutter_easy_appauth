import 'package:flutter_easy_appauth/src/service_config.dart';

import 'common_request.dart';
import 'package:flutter/material.dart';

class AuthorizationRequest extends CommonRequest{

  String clientSecret;

  AuthorizationRequest({
    @required String clientId,
    @required ServiceConfig serviceConfig,
    @required String redirectUrl,
    @required String issuer,
    @required String discoveryUrl,
    @required String clientSecret,
    @required List<String> scopes,
    bool allowInsecureConnections}){
    this.clientId = clientId;
    this.redirectUrl = redirectUrl;
    this.scopes = scopes;
    this.serviceConfig = serviceConfig;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
    this.allowInsecureConnections = allowInsecureConnections;

    this.clientSecret = clientSecret;
  }

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map["clientSecret"] = this.clientSecret;
    return map;
  }
}