package easyappauth.flutter_easy_appauth;

import android.content.Intent;
import android.net.Uri;

import net.openid.appauth.AppAuthConfiguration;
import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationRequest;
import net.openid.appauth.AuthorizationResponse;
import net.openid.appauth.AuthorizationService;
import net.openid.appauth.AuthorizationServiceConfiguration;
import net.openid.appauth.ClientSecretBasic;
import net.openid.appauth.ResponseTypeValues;
import net.openid.appauth.TokenRequest;
import net.openid.appauth.TokenResponse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterEasyAppauthPlugin */
public class FlutterEasyAppauthPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
  /** Plugin registration. */
  private Registrar registrar;
  private PendingOperation pendingOperation;
  private AuthorizationTokenRequestParameters tokenRequestParameters;

  private FlutterEasyAppauthPlugin(Registrar registrar) {
    this.registrar = registrar;
    this.registrar.addActivityResultListener(this);
  }

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_easy_appauth");
    channel.setMethodCallHandler(new FlutterEasyAppauthPlugin(registrar));
  }





  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Map<String, Object> arguments = call.arguments();
    if (call.method.equals("authorizeAndExchangeCode")) {
      checkAndSetPendingOperation(call.method, result);
      handleAuthorizeMethodCall(arguments);
    } else {
      result.notImplemented();
    }
  }

  //保存回掉
  private void checkAndSetPendingOperation(String method, Result result) {
    if (pendingOperation != null) {
      throw new IllegalStateException(
              "Concurrent operations detected: " + pendingOperation.method + ", " + method);
    }
    pendingOperation = new PendingOperation(method, result);
  }

  //处理成功回掉
  private void finishWithSuccess(Object data) {
    Map<String, Object> responseMap = new HashMap<>();
    responseMap.put("error","0");
    responseMap.put("message","授权成功");
    responseMap.put("response",data);
    pendingOperation.result.success(responseMap);
    pendingOperation = null;
  }

  //处理失败回掉
  private void finishWithfaild(String errorCode, String message) {
    Map<String, Object> responseMap = new HashMap<>();
    responseMap.put("error",errorCode==null?"1":errorCode);
    responseMap.put("message",message);
    pendingOperation.result.success(responseMap);
    pendingOperation = null;
  }

  //处理登录
  private void handleAuthorizeMethodCall(Map<String, Object> arguments) {
    tokenRequestParameters = processAuthorizationTokenRequestArguments(arguments);
    AuthorizationServiceConfiguration serviceConfiguration = requestParametersToServiceConfiguration(tokenRequestParameters);

    AuthorizationRequest.Builder authRequestBuilder =
            new AuthorizationRequest.Builder(
                    serviceConfiguration,
                    tokenRequestParameters.clientId,
                    ResponseTypeValues.CODE,
                    Uri.parse(tokenRequestParameters.redirectUrl));

      authRequestBuilder.setScopes(tokenRequestParameters.scopes);

    AppAuthConfiguration.Builder authConfigBuilder = new AppAuthConfiguration.Builder();
    if (tokenRequestParameters.allowInsecureConnections) {
      authConfigBuilder.setConnectionBuilder(InsecureConnectionBuilder.INSTANCE);
    }

    AppAuthConfiguration authConfig = authConfigBuilder.build();
    AuthorizationRequest authRequest = authRequestBuilder.build();
    AuthorizationService authService = new AuthorizationService(registrar.context(), authConfig);
    Intent authIntent = authService.getAuthorizationRequestIntent(authRequest);
    //触发调转新页面登录
    registrar.activity().startActivityForResult(authIntent,8888);

  }


  //关闭登录界面回掉
  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
    if (pendingOperation == null) {
      return false;
    }
    if (requestCode == 8888) {
      final AuthorizationResponse authResponse = AuthorizationResponse.fromIntent(intent);
      AuthorizationException ex = AuthorizationException.fromIntent(intent);
      if (authResponse == null){
        finishWithfaild(ex.error,ex.errorDescription);
        return true;
      }

      AppAuthConfiguration.Builder authConfigBuilder = new AppAuthConfiguration.Builder();
      if (tokenRequestParameters.allowInsecureConnections) {
        authConfigBuilder.setConnectionBuilder(InsecureConnectionBuilder.INSTANCE);
      }

      AppAuthConfiguration authConfig = authConfigBuilder.build();
      AuthorizationService authService = new AuthorizationService(registrar.context(), authConfig);
      AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
        @Override
        public void onTokenRequestCompleted(
                TokenResponse resp, AuthorizationException ex) {
          if (resp != null) {
            Map<String, Object> responseMap = new HashMap<>();
            finishWithSuccess(tokenResponseToMap(resp, authResponse));
          } else {
            finishWithfaild(ex.error,ex.errorDescription);
            //finishWithError(AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE, String.format(AUTHORIZE_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription));
          }
        }
      };
      authService.performTokenRequest(authResponse.createTokenExchangeRequest(), new ClientSecretBasic(tokenRequestParameters.clientSecret), tokenResponseCallback);
      return true;
    }
    return false;
  }












  private AuthorizationServiceConfiguration requestParametersToServiceConfiguration(TokenRequestParameters tokenRequestParameters) {
    return new AuthorizationServiceConfiguration(Uri.parse(tokenRequestParameters.serviceConfigurationParameters.get("authorizationEndpoint")), Uri.parse(tokenRequestParameters.serviceConfigurationParameters.get("tokenEndpoint")));
  }

  private AuthorizationTokenRequestParameters processAuthorizationTokenRequestArguments(Map<String, Object> arguments) {
    final String clientId = (String) arguments.get("clientId");
    final String issuer = (String) arguments.get("issuer");
    final String discoveryUrl = (String) arguments.get("discoveryUrl");
    final String redirectUrl = (String) arguments.get("redirectUrl");
    final String clientSecret = (String) arguments.get("clientSecret");
    final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
    Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
    final Boolean allowInsecureConnections = (Boolean) arguments.get("allowInsecureConnections");

    return new AuthorizationTokenRequestParameters(clientId, clientSecret,issuer, discoveryUrl, scopes, redirectUrl, serviceConfigurationParameters,allowInsecureConnections);
  }


  private Map<String, Object> tokenResponseToMap(TokenResponse tokenResponse, AuthorizationResponse authResponse) {
    Map<String, Object> responseMap = new HashMap<>();
    responseMap.put("accessToken", tokenResponse.accessToken);
    responseMap.put("accessTokenExpirationTime", tokenResponse.accessTokenExpirationTime != null ? tokenResponse.accessTokenExpirationTime.doubleValue() : null);
    responseMap.put("refreshToken", tokenResponse.refreshToken);
    responseMap.put("idToken", tokenResponse.idToken);
    responseMap.put("tokenType", tokenResponse.tokenType);
    if (authResponse != null) {
      responseMap.put("authorizationAdditionalParameters", authResponse.additionalParameters);
    }
    responseMap.put("tokenAdditionalParameters", tokenResponse.additionalParameters);

    return responseMap;
  }

  private Map<String, Object> authorizationResponseToMap(AuthorizationResponse authResponse) {
    Map<String, Object> responseMap = new HashMap<>();
    responseMap.put("codeVerifier", authResponse.request.codeVerifier);
    responseMap.put("authorizationCode", authResponse.authorizationCode);
    responseMap.put("authorizationAdditionalParameters", authResponse.additionalParameters);
    return responseMap;
  }

  private class PendingOperation {
    final String method;
    final Result result;

    PendingOperation(String method, Result result) {
      this.method = method;
      this.result = result;
    }
  }


  private class TokenRequestParameters {
    final String clientId;
    final String issuer;
    final String discoveryUrl;
    final ArrayList<String> scopes;
    final String redirectUrl;
    final String refreshToken;
    final String grantType;
    final String clientSecret;
    final String codeVerifier;
    final String authorizationCode;
    final Map<String, String> serviceConfigurationParameters;
    final Boolean allowInsecureConnections;

    private TokenRequestParameters(String clientId,String clientSecret, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl,Map<String, String> serviceConfigurationParameters,Boolean allowInsecureConnections, String refreshToken, String authorizationCode, String grantType, String codeVerifier) {
      this.clientId = clientId;
      this.issuer = issuer;
      this.discoveryUrl = discoveryUrl;
      this.scopes = scopes;
      this.redirectUrl = redirectUrl;
      this.refreshToken = refreshToken;
      this.authorizationCode = authorizationCode;
      this.codeVerifier = codeVerifier;
      this.grantType = grantType;
      this.clientSecret = clientSecret;
      this.serviceConfigurationParameters = serviceConfigurationParameters;
      this.allowInsecureConnections = allowInsecureConnections;
    }
  }

  private class AuthorizationTokenRequestParameters extends TokenRequestParameters {

    private AuthorizationTokenRequestParameters(String clientId,String clientSecret, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, Map<String, String> serviceConfigurationParameters,Boolean allowInsecureConnections) {
      super(clientId,clientSecret, issuer, discoveryUrl, scopes, redirectUrl, serviceConfigurationParameters,allowInsecureConnections, null, null, null, null);

    }
  }
}
