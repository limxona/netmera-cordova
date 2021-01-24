/********* NetmeraPlugin.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "NetmeraPlugin.h"
#import <Netmera/Netmera.h>
#import <objc/runtime.h>
#import "FNetmeraUser.h"


@implementation NetmeraPlugin

NetmeraInbox *netmeraInbox = nil;
CDVInvokedUrlCommand *inboxCommandId = nil;
@synthesize notificationCallbackId;
@synthesize openUrlCallbackId;

static NetmeraPlugin *netmeraPlugin;

+ (NetmeraPlugin *) netmeraPlugin {
    return netmeraPlugin;
}

- (void)pluginInitialize {
    NSLog(@"Starting Netmera plugin");
    netmeraPlugin = self;
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* key = [command.arguments objectAtIndex:0];
    
    [Netmera setAPIKey:key];
    [Netmera setLogLevel:(NetmeraLogLevelDebug)];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)requestPushNotificationAuthorization:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    [Netmera requestPushNotificationAuthorizationForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)registerPushNotification:(CDVInvokedUrlCommand*)command
{
    self.notificationCallbackId = command.callbackId;
}

- (void)registerOpenUrl:(CDVInvokedUrlCommand*)command
{
    self.openUrlCallbackId = command.callbackId;
}

- (void)sendNotification:(NSDictionary *)userInfo {
    if (self.notificationCallbackId != nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userInfo];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.notificationCallbackId];
    } else {
        //        if (!self.notificationStack) {
        //            self.notificationStack = [[NSMutableArray alloc] init];
        //        }
        //
        //        // stack notifications until a callback has been registered
        //        [self.notificationStack addObject:userInfo];
        //
        //        if ([self.notificationStack count] >= kNotificationStackSize) {
        //            [self.notificationStack removeLastObject];
        //        }
    }
}

- (void)sendOpenUrl:(NSString*)openUrl
{
    if (self.openUrlCallbackId != nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:openUrl];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.openUrlCallbackId];
    }
}


- (void)sendEvent:(CDVInvokedUrlCommand*)command
{
    
    CDVPluginResult* pluginResult = nil;
    NSMutableDictionary *eventDict = [command.arguments objectAtIndex:0];
    
    /*
     NSMutableDictionary* mutableEventDictionary = [command.arguments objectAtIndex:1];
     NSArray *keysForNullValues = [mutableEventDictionary allKeysForObject:[NSNull null]];
     [mutableEventDictionary removeObjectsForKeys:keysForNullValues];
     FNetmeraEvent *event = [FNetmeraEvent event];
     event.netmeraEventKey = mutableEventDictionary[@"code"];
     [mutableEventDictionary removeObjectForKey:@"code"];
     event.eventParameters = mutableEventDictionary;
     [Netmera sendEvent:event];
     */
    
    
    NetmeraEvent *event = [[NetmeraEvent alloc] initWithDictionary:eventDict];
    [Netmera sendEvent:event];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void)fetchInboxUsingFilter:(CDVInvokedUrlCommand*)command
{
    NSDictionary* userFilter = [command.arguments objectAtIndex:0];
    inboxCommandId = command;
    
    NetmeraInboxFilter *filter = [[NetmeraInboxFilter alloc] init];
    filter.status = [[userFilter valueForKey:@"status"] intValue];
    filter.pageSize = [[userFilter valueForKey:@"pageSize"] intValue];
    filter.categories = [userFilter valueForKey:@"categories"];
    filter.shouldIncludeExpiredObjects = [userFilter valueForKey:@"shouldIncludeExpiredObjects"];
    
    [Netmera fetchInboxUsingFilter:filter
                        completion:^(NetmeraInbox *inbox, NSError *error) {
        CDVPluginResult* pluginResult = nil;
        if(error) {
            NSLog(@"Error : %@", [error debugDescription]);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }
        else {
            netmeraInbox = inbox;
            
            NSDictionary *pluginResponse = [self getInboxList:inbox];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pluginResponse];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (NSDictionary*)getInboxList:(NetmeraInbox*)inbox
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    
    NSMutableArray *inboxList = [NSMutableArray array];
    for(NetmeraPushObject *pushObject in inbox.objects)
    {
        NSDictionary *pluginResponse = @{
            @"pushId": pushObject.pushId,
            @"pushInstanceId": pushObject.pushInstanceId,
            @"badge": [pushObject valueForKey:@"badge"],
            @"pushType": [pushObject valueForKey:@"pushType"],
            @"title": [[pushObject valueForKey:@"alert"] valueForKey:@"title"],
            @"subtitle": [[pushObject valueForKey:@"alert"] valueForKey:@"subtitle"],
            @"body": [[pushObject valueForKey:@"alert"] valueForKey:@"body"],
            @"inboxStatus": [pushObject valueForKey:@"inboxStatus"],
            @"sendDate": [formatter stringFromDate:pushObject.sendDate],
        };
        //NSDictionary *dict = pushObject.dictionaryValue;
        [inboxList addObject:pluginResponse];
    }
    NSDictionary *pluginResponse = @{
        @"hasNextPage": @(inbox.hasNextPage),
        @"inbox": inboxList
    };
    
    return pluginResponse;
}

- (void)fetchNextPage:(CDVInvokedUrlCommand*)command
{
    [netmeraInbox fetchNextPageWithCompletionBlock:^(NSError *error) {
        CDVPluginResult* pluginResult = nil;
        if(error) {
            NSLog(@"Error : %@", [error debugDescription]);
        }
        else {
            NSDictionary *pluginResponse = [self getInboxList:netmeraInbox];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pluginResponse];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)countForStatus:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSNumber* countType = [command.arguments objectAtIndex:0];
    int countInt = [countType intValue];
    NSUInteger numberOfValue = 0;
    numberOfValue = [netmeraInbox countForStatus:countInt];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:(int) numberOfValue];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)updatePushStatus:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    int index = [[command.arguments objectAtIndex:0] intValue];
    int length = [[command.arguments objectAtIndex:1] intValue];
    int status = [[command.arguments objectAtIndex:2] intValue];
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, length)];
    NSArray *objectList = [netmeraInbox.objects objectsAtIndexes:set];
    [netmeraInbox updateStatus:status
                forPushObjects:objectList
                    completion:^(NSError *error) {
        if(error) {
            NSLog(@"Error : %@", [error debugDescription]);
        } else {
            NSLog(@"OK");
        }
    }];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)updateUser:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    NSMutableDictionary *userMutableDictionary = [command.arguments objectAtIndex:0];
    NSArray *keysForNullValues = [userMutableDictionary allKeysForObject:[NSNull null]];
    [userMutableDictionary removeObjectsForKeys:keysForNullValues];
    FNetmeraUser *user = [[FNetmeraUser alloc] init];
    user.userId=[userMutableDictionary objectForKey:@"userId"];
    user.MSISDN=[userMutableDictionary objectForKey:@"msisdn"];
    user.email=[userMutableDictionary objectForKey:@"email"];
    [userMutableDictionary removeObjectForKey:@"userId"];
    [userMutableDictionary removeObjectForKey:@"email"];
    [userMutableDictionary removeObjectForKey:@"msisdn"];
    user.userParameters = userMutableDictionary;
    [Netmera updateUser:user];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
