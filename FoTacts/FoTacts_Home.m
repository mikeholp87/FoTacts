//
//  FoTacts_Home.m
//  FoTacts
//
//  Created by Mike Holp on 2/6/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "FoTacts_Home.h"

#define kNavTintColor [UIColor colorWithRed:231/255.0 green:126/255.0 blue:15/255.0 alpha:1.000]

@implementation FoTacts_Home
@synthesize eventStore, userPhoto, existingLbl, actionSheet, timePicker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = kNavTintColor;
    self.navigationItem.rightBarButtonItem.tintColor = kNavTintColor;
    
    eventStore = [[EKEventStore alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    
    userInfo = [[NSUserDefaults alloc] init];
    NSString *imagePath = [userInfo objectForKey:@"user_photo"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:imagePath]){
        existingLbl.hidden = NO;
        [userPhoto setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)sendTweet:(id)sender
{
    if([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet setInitialText:[NSString stringWithFormat:@"Show the people you're meeting exactly what you look like today. Get the app for free now! www.fotacts.co @FoTacts"]];
            [self presentViewController:tweetSheet animated:YES completion:nil];
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }else{
        NSURL *url = [NSURL URLWithString:@"www.dwmcapp.com"];
        SHKItem *item = [SHKItem URL:url title:@"Never Lose Your Car Again! Download \"Dude Where's My Car?\" for FREE!"];
        [SHKTwitter shareItem:item];
    }
}

- (IBAction)postStatus:(id)sender
{
    if([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
            SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
                if (result == SLComposeViewControllerResultCancelled)
                    NSLog(@"Cancelled");
                else
                    NSLog(@"Done");
                
                [controller dismissViewControllerAnimated:YES completion:Nil];
            };
            controller.completionHandler = myBlock;
            
            [controller setInitialText:@"Show the people you're meeting exactly what you look like today. Get the app for free now! @FoTacts"];
            [controller addURL:[NSURL URLWithString:@"www.fotacts.co"]];
            [controller addImage:[UIImage imageNamed:@"AppIcon.png"]];
            
            [self presentViewController:controller animated:YES completion:Nil];
            
        }
        else{
            NSLog(@"Unavailable");
        }
    }else{
        NSURL *url = [NSURL URLWithString:@"www.dwmcapp.com"];
        SHKItem *item = [SHKItem URL:url title:@"Never Lose Your Car Again! Download \"Dude Where's My Car?\" for FREE!"];
        [SHKFacebook shareItem:item];
    }
}

- (IBAction)usePhoto:(id)sender
{
    FoTacts_Meetup *meetup = [self.storyboard instantiateViewControllerWithIdentifier:@"FoTacts_Meetup"];
    meetup.title = @"Meeting Details";
    meetup.picture = userPhoto.imageView.image;
    [self.navigationController pushViewController:meetup animated:YES];
}

- (IBAction)setAlarm:(id)sender
{
    [self createActionSheet];
}

- (void)createActionSheet {
    actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.clipsToBounds = YES;
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    pickerToolbar.barStyle = UIBarStyleBlackOpaque;
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerDone:)];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissActionSheet)];
    
    NSArray *itemsArray = @[cancel, flexibleItem, done];
    
    [pickerToolbar setItems:itemsArray];
    
    [actionSheet addSubview:pickerToolbar];
    
    timePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 44.0, 320.0, 216.0)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerDone:)];
    [timePicker addGestureRecognizer:tap];
    
    [actionSheet addSubview:timePicker];
    [actionSheet showInView:self.view];
    [actionSheet setBounds:CGRectMake(0,0,320,550)];
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
}

- (void)sendLocalNotification:(NSDate *)date
{
    UIApplication *application = [UIApplication sharedApplication];
    NSArray *scheduledNotifications = [NSArray arrayWithArray:application.scheduledLocalNotifications];
    
    if([scheduledNotifications count] > 0)
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    
    // Notification details
    localNotif.fireDate = date;
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.alertAction = @"View";
    localNotif.alertBody = @"Take a photo";
    localNotif.repeatInterval = NSDayCalendarUnit;
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 0;
    
    // Schedule the notification
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    
    NSLog(@"%@", scheduledNotifications);
}

- (void)dismissActionSheet
{
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)pickerDone:(id)sender
{
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    [self sendLocalNotification:self.timePicker.date];
}

- (IBAction)showCalendar:(id)sender
{
    /* iOS 6 requires the user grant your application access to the Event Stores */
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        /* iOS Settings > Privacy > Calendars > MY APP > ENABLE | DISABLE */
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
         {
             if (granted){
                 NSLog(@"User has granted permission!");
                 UIViewController *events = [self.storyboard instantiateViewControllerWithIdentifier:@"FoTacts_Events"];
                 [self.navigationController pushViewController:events animated:YES];
             }else{
                 NSLog(@"User has not granted permission!");
                 [[[UIAlertView alloc] initWithTitle:@"FoTacts" message:@"You do not have access to your calendar." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
             }
         }];
    }
}

@end
