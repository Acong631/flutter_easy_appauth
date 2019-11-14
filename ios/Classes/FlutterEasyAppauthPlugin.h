#import <Flutter/Flutter.h>

@protocol OIDExternalUserAgentSession;
@interface FlutterEasyAppauthPlugin : NSObject<FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;
@end
