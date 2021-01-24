#import <Cordova/CDVPlugin.h>

@interface NetmeraPlugin : CDVPlugin {
  // Member variables go here.
}

@property (nonatomic, copy) NSString *notificationCallbackId;
@property (nonatomic, copy) NSString *openUrlCallbackId;

+ (NetmeraPlugin *) netmeraPlugin;
- (void)start:(CDVInvokedUrlCommand*)command;
- (void)requestPushNotificationAuthorization:(CDVInvokedUrlCommand*)command;
- (void)registerPushNotification:(CDVInvokedUrlCommand*)command;
- (void)registerOpenUrl:(CDVInvokedUrlCommand*)command;
- (void)sendNotification:(NSDictionary*)userInfo;
- (void)sendOpenUrl:(NSString*)openUrl;
- (void)sendEvent:(CDVInvokedUrlCommand*)command;
- (void)fetchInboxUsingFilter:(CDVInvokedUrlCommand*)command;
- (void)fetchNextPage:(CDVInvokedUrlCommand*)command;
- (void)countForStatus:(CDVInvokedUrlCommand*)command;
- (void)updatePushStatus:(CDVInvokedUrlCommand*)command;
- (void)updateUser:(CDVInvokedUrlCommand*)command;
@end
