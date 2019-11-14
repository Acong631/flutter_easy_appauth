import 'mappable.dart';
import 'service_config.dart';

class CommonRequest implements Mappable{

  String clientId;
  String issuer;
  String discoveryUrl;
  String redirectUrl;
  List<String> scopes;
  ServiceConfig serviceConfig;

  bool allowInsecureConnections;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clientId': clientId,
      'issuer': issuer,
      'discoveryUrl': discoveryUrl,
      'redirectUrl': redirectUrl,
      'scopes': scopes,
      'serviceConfiguration': serviceConfig?.toMap(),
      'allowInsecureConnections': allowInsecureConnections
    };
  }

}