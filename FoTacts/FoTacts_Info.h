//
//  FoTacts_Info.h
//  FoTacts
//
//  Created by Mike Holp on 1/31/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "SHK.h"

@interface FoTacts_Info : UIViewController<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSUserDefaults *userInfo;
    NSUserDefaults *alarmDate;
    CGFloat animatedDistance;
}

@property (nonatomic, retain) IBOutlet UITextField *firstNameField;
@property (nonatomic, retain) IBOutlet UITextField *lastNameField;
@property (nonatomic, retain) IBOutlet UITextField *emailField;
@property (nonatomic, retain) IBOutlet UITextField *phoneField;
@property (nonatomic, retain) IBOutlet UILabel *datetimeLabel;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *twitterButton;
@property(nonatomic,retain) IBOutlet UIDatePicker *timePicker;

@property(nonatomic,retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) UISegmentedControl *segControl;

@end
