//
//  AppDelegate.m
//  FoTacts
//
//  Created by Mike Holp on 1/31/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    //UILocalNotification *localNotif = [launchOptions objectForKey: UIApplicationLaunchOptionsLocalNotificationKey];
    
    //[self showPhotoView];
    
    return YES;
}

- (void)showPhotoView
{
    UIStoryboard *mainstoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    FoTacts_Photo *photoView = [mainstoryboard instantiateViewControllerWithIdentifier:@"FoTacts_Photo"];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentModalViewController:photoView animated:YES];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"Incoming notification in running app");
    
    //[[[UIAlertView alloc] initWithTitle:@"FoTacts Alert" message:@"Upcoming Meeting" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end
