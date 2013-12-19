//
//  BMXAppDelegate.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXAppDelegate.h"

@implementation BMXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        self.window.tintColor = [UIColor colorWithRed: 57.0 / 255
                                                green: 109.0 / 255
                                                 blue: 187.0 / 255
                                                alpha: 1.0];
    }

    return YES;
}

@end
