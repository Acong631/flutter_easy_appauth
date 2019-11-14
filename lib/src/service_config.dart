import 'mappable.dart';

class ServiceConfig implements Mappable{
  final String authorizationEndpoint;
  final String tokenEndpoint;

  ServiceConfig(
      this.authorizationEndpoint, this.tokenEndpoint)
      : assert(tokenEndpoint != null && authorizationEndpoint != null,
  'Must specify both the authorization and token endpoints');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tokenEndpoint': tokenEndpoint,
      'authorizationEndpoint': authorizationEndpoint
    };
  }
}