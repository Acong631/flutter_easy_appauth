#import "FlutterEasyAppauthPlugin.h"
#import "AppAuth.h"

@interface ArgumentProcessor : NSObject
+ (id _Nullable)processArgumentValue:(NSDictionary *)arguments withKey:(NSString *)key;
@end

@implementation ArgumentProcessor

+ (id _Nullable)processArgumentValue:(NSDictionary *)arguments withKey:(NSString *)key {
    return [arguments objectForKey:key] != [NSNull null] ? arguments[key] : nil;
}

@end

@interface TokenRequestParameters : NSObject
@property(nonatomic, strong) NSString *clientId;
@property(nonatomic, strong) NSString *clientSecret;
@property(nonatomic, strong) NSString *issuer;
@property(nonatomic, strong) NSString *grantType;
@property(nonatomic, strong) NSString *discoveryUrl;
@property(nonatomic, strong) NSString *redirectUrl;
@property(nonatomic, strong) NSString *refreshToken;
@property(nonatomic, strong) NSString *codeVerifier;
@property(nonatomic, strong) NSString *authorizationCode;
@property(nonatomic, strong) NSArray *scopes;
@property(nonatomic, strong) NSDictionary *serviceConfigurationParameters;
@property(nonatomic, strong) NSDictionary *additionalParameters;

@end

@implementation TokenRequestParameters
- (void)processArguments:(NSDictionary *)arguments {
    _clientId = [ArgumentProcessor processArgumentValue:arguments withKey:@"clientId"];
    _clientSecret = [ArgumentProcessor processArgumentValue:arguments withKey:@"clientSecret"];
    _issuer = [ArgumentProcessor processArgumentValue:arguments withKey:@"issuer"];
    _discoveryUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"discoveryUrl"];
    _redirectUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"redirectUrl"];
    _refreshToken = [ArgumentProcessor processArgumentValue:arguments withKey:@"refreshToken"];
    _authorizationCode = [ArgumentProcessor processArgumentValue:arguments withKey:@"authorizationCode"];
    _codeVerifier = [ArgumentProcessor processArgumentValue:arguments withKey:@"codeVerifier"];
    _grantType = [ArgumentProcessor processArgumentValue:arguments withKey:@"grantType"];
    _scopes = [ArgumentProcessor processArgumentValue:arguments withKey:@"scopes"];
    _serviceConfigurationParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"serviceConfiguration"];
    _additionalParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"additionalParameters"];
}

- (id)initWithArguments:(NSDictionary *)arguments {
    [self processArguments:arguments];
    return self;
}

@end

@interface AuthorizationTokenRequestParameters : TokenRequestParameters
@property(nonatomic, strong) NSString *loginHint;
@property(nonatomic, strong) NSArray *promptValues;
@end



@implementation AuthorizationTokenRequestParameters
- (id)initWithArguments:(NSDictionary *)arguments {
    [super processArguments:arguments];
    _loginHint = [ArgumentProcessor processArgumentValue:arguments withKey:@"loginHint"];
    _promptValues = [ArgumentProcessor processArgumentValue:arguments withKey:@"promptValues"];
    return self;
}
@end

@interface FlutterEasyAppauthPlugin ()
@property(nonatomic, strong) AuthorizationTokenRequestParameters *requestParameters;
@end


@implementation FlutterEasyAppauthPlugin

//
NSString *const AUTHORIZE_AND_EXCHANGE_CODE_METHOD = @"authorizeAndExchangeCode";
NSString *const TOKEN_METHOD = @"token";



+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_easy_appauth"
            binaryMessenger:[registrar messenger]];
  FlutterEasyAppauthPlugin* instance = [[FlutterEasyAppauthPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([AUTHORIZE_AND_EXCHANGE_CODE_METHOD isEqualToString:call.method]) {
        [self handleAuthorizeMethodCall:[call arguments] result:result exchangeCode:true];
    } else if([TOKEN_METHOD isEqualToString:call.method]) {
        //[self handleTokenMethodCall:[call arguments] result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)handleAuthorizeMethodCall:(NSDictionary*)arguments result:(FlutterResult)result exchangeCode:(BOOL)exchangeCode {
    self.requestParameters = [[AuthorizationTokenRequestParameters alloc] initWithArguments:arguments];
    
    //配置config
    OIDServiceConfiguration *serviceConfiguration = [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:[NSURL URLWithString:self.requestParameters.serviceConfigurationParameters[@"authorizationEndpoint"]]
     tokenEndpoint:[NSURL URLWithString:self.requestParameters.serviceConfigurationParameters[@"tokenEndpoint"]]];

    
    //请求
    OIDAuthorizationRequest *request =
    [[OIDAuthorizationRequest alloc] initWithConfiguration:serviceConfiguration
                                                  clientId:self.requestParameters.clientId
                                              clientSecret:self.requestParameters.clientSecret
                                                    scopes:self.requestParameters.scopes
                                               redirectURL:[NSURL URLWithString:self.requestParameters.redirectUrl]
                                              responseType:OIDResponseTypeCode
                                      additionalParameters:nil];

    //打开登录网页
    NSLog(@"%@", request);
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    _currentAuthorizationFlow = [OIDAuthState authStateByPresentingAuthorizationRequest:request presentingViewController:rootViewController callback:^(OIDAuthState * _Nullable authState, NSError * _Nullable error) {
        if (authState) {
            NSMutableDictionary *dic = [self processResponses:authState.lastTokenResponse authResponse:authState.lastAuthorizationResponse];
            result(@{@"response":dic,@"error":@"0",@"message":@"授权成功"});
        }else{
            result(@{@"error":error.code?@(error.code):@"1",@"message":error.description});
        }
    }];

}

- (NSMutableDictionary *)processResponses:(OIDTokenResponse*) tokenResponse authResponse:(OIDAuthorizationResponse*) authResponse {
    NSMutableDictionary *processedResponses = [[NSMutableDictionary alloc] init];
    if(tokenResponse.accessToken) {
        [processedResponses setValue:tokenResponse.accessToken forKey:@"accessToken"];
    }
    if(tokenResponse.accessTokenExpirationDate) {
        [processedResponses setValue:[[NSNumber alloc] initWithDouble:[tokenResponse.accessTokenExpirationDate timeIntervalSince1970] * 1000] forKey:@"accessTokenExpirationTime"];
    }
    if(authResponse && authResponse.additionalParameters) {
        [processedResponses setObject:authResponse.additionalParameters forKey:@"authorizationAdditionalParameters"];
    }
    if(tokenResponse.additionalParameters) {
        [processedResponses setObject:tokenResponse.additionalParameters forKey:@"tokenAdditionalParameters"];
    }
    if(tokenResponse.idToken) {
        [processedResponses setValue:tokenResponse.idToken forKey:@"idToken"];
    }
    if(tokenResponse.refreshToken) {
        [processedResponses setValue:tokenResponse.refreshToken forKey:@"refreshToken"];
    }
    if(tokenResponse.tokenType) {
        [processedResponses setValue:tokenResponse.tokenType forKey:@"tokenType"];
    }
    
    return processedResponses;
}


@end
