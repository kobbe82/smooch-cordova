/*
 * SmoochCordova.h
 * Smooch Cordova/Phonegap Plugin
 *
 * Learn more and sign up at http://smooch.io
 *
*/

#import <Cordova/CDV.h>

@protocol SKTConversationDelegate;

@interface SmoochCordova : CDVPlugin

@property(weak, nullable) id<SKTConversationDelegate> delegate;

- (void)init:(CDVInvokedUrlCommand *)command;
- (void)show:(CDVInvokedUrlCommand *)command;
- (void)login:(CDVInvokedUrlCommand *)command;
- (void)logout:(CDVInvokedUrlCommand *)command;

- (void)setUser:(CDVInvokedUrlCommand *)command;
- (void)setUserProperties:(CDVInvokedUrlCommand *)command;

@end
