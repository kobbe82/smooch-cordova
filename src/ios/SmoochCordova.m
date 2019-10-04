/*
 * SmoochCordova.m
 * Smooch Cordova/Phonegap Plugin
 *
 * Learn more and sign up at http://smooch.io
 *
*/

#import "SmoochCordova.h"
#import <Smooch/Smooch.h>

@implementation SmoochCordova


- (void)init:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc]
        initWithDictionary:[command argumentAtIndex:0]];

    SKTSettings *sktSettingsObj = [[SKTSettings alloc] init];


    if ([settings valueForKey:@"conversationAccentColor"]) {
        sktSettingsObj.conversationAccentColor = [SmoochCordova colorFromHexString:[settings valueForKey:@"conversationAccentColor"]];
        [settings removeObjectForKey:@"conversationAccentColor"];
    }

    [sktSettingsObj setValuesForKeysWithDictionary:settings];
    [Smooch initWithSettings:sktSettingsObj completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
        if(!error){
            SKTConversation *conversation = [Smooch conversation];
            conversation.delegate = self;
            [self sendSuccess:command];
        } else {
            [self sendFailure:command];
        }
    }];
}

- (void)show:(CDVInvokedUrlCommand *)command {
    [Smooch show];
    [self sendSuccess:command];
}

- (void)login:(CDVInvokedUrlCommand *)command {
    NSString *userId = [command argumentAtIndex:0];
    NSString *jwt = [command argumentAtIndex:1];

    [Smooch login:userId jwt:jwt completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
        if(!error){
            [self sendSuccess:command];
        } else {
            [self sendFailure:command];
        }
    }];
}

- (void)logout:(CDVInvokedUrlCommand *)command {
    [Smooch logoutWithCompletionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
        if(!error){
            [self sendSuccess:command];
        } else {
            [self sendFailure:command];
        }
    }];
}

- (void)conversation:(SKTConversation *)conversation unreadCountDidChange:(NSUInteger)unreadCount {
    NSDictionary *data = @{@"unreadCount": @(unreadCount)};
    NSString *jsCommand = [self generateEventCommand:@"unreadCountDidChange" withdata:data];
    [self.commandDelegate evalJs:jsCommand scheduledOnRunLoop:NO];
}

- (void)conversation:(SKTConversation *)conversation didReceiveActivity:(nonnull SKTConversationActivity *)activity {
   NSDictionary *data = @{@"role": activity.role, @"type": activity.type, @"data": activity.data, @"appMarkerLastRead": activity.appMakerLastRead};
   NSString *jsCommand = [self generateEventCommand:@"didReceiveActivity" withdata:data];
   [self.commandDelegate evalJs:jsCommand scheduledOnRunLoop:NO];
}

- (void)conversation:(SKTConversation *)conversation willShowViewController:(UIViewController *)viewController {
   NSString *jsCommand = [self generateEventCommand:@"willShowViewController" withdata:nil];
   [self.commandDelegate evalJs:jsCommand scheduledOnRunLoop:NO];
}

- (void)conversation:(SKTConversation *)conversation didShowViewController:(UIViewController *)viewController {
    NSString *jsCommand = [self generateEventCommand:@"didShowViewController" withdata:nil];
    [self.commandDelegate evalJs:jsCommand scheduledOnRunLoop:NO];
}

- (void)conversation:(SKTConversation *)conversation didDismissViewController:(nonnull UIViewController *)viewController {
    NSString *jsCommand = [self generateEventCommand:@"didDismissViewController" withdata:nil];
    [self.commandDelegate evalJs:jsCommand scheduledOnRunLoop:NO];
}

- (void)conversation:(SKTConversation *)conversation willDismissViewController:(nonnull UIViewController *)viewController {
    NSString *jsCommand = [self generateEventCommand:@"willDismissViewController" withdata:nil];
    [self.commandDelegate evalJs:jsCommand scheduledOnRunLoop:NO];
}

#pragma mark - User

- (void)setUser:(CDVInvokedUrlCommand *)command {
    NSDictionary *user = [command argumentAtIndex:0];

    SKTUser *currentUser = [SKTUser currentUser];
    [currentUser setValuesForKeysWithDictionary:user];

    id timestamp = [user valueForKey:@"signedUpAt"];
    if (timestamp && [timestamp isKindOfClass:[NSNumber class]]) {
        NSTimeInterval seconds = [timestamp doubleValue] / 1000; // covert from milliseconds to seconds
        [currentUser setSignedUpAt:[NSDate dateWithTimeIntervalSince1970:seconds]];
    }

    [self sendSuccess:command];
}

- (void)setUserProperties:(CDVInvokedUrlCommand *)command {
    NSDictionary *properties = [command argumentAtIndex:0];

    SKTUser *currentUser = [SKTUser currentUser];
    [currentUser addProperties:properties];

    [self sendSuccess:command];
}

#pragma mark - Private Methods

- (void)sendSuccess:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendFailure:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSString *)generateEventCommand:(NSString *)type withdata:(nullable NSDictionary *)data {
    NSMutableDictionary *eventargument = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *details = [[NSMutableDictionary alloc] init];

    details[@"type"] = type;
    if(data != nil) {
        details[@"data"] = data;
    }

    eventargument[@"detail"] = details;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventargument
      options:0
      error:nil];

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *result = [NSString stringWithFormat:@"cordova.fireDocumentEvent('smoochconversation', %@);", jsonString];
    return result;
}

// Assumes input like "#00FF00" (#RRGGBB).
+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
@end