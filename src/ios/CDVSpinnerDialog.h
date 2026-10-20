//
//  CDVSpinnerDialog.h
//
//  Created by Domonkos Pál on 2014.01.27..
//
//

#import <Cordova/CDVPlugin.h>

@interface CDVSpinnerDialog : CDVPlugin

- (void)show:(CDVInvokedUrlCommand*)command;
- (void)hide:(CDVInvokedUrlCommand*)command;

@end
