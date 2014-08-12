//
//  FoTacts_Home.h
//  FoTacts
//
//  Created by Mike Holp on 2/6/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <EventKit/EventKit.h>
#import "SHKTwitter.h"
#import "SHKFacebook.h"
#import "FoTacts_Meetup.h"

@interface FoTacts_Home : UIViewController<UIActionSheetDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSUserDefaults *userInfo;
}

@property (nonatomic, retain) UIDatePicker *timePicker;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) IBOutlet UIButton *userPhoto;
@property (nonatomic, retain) IBOutlet UIButton *useCamera;
@property (nonatomic, retain) IBOutlet UILabel *existingLbl;
@property (nonatomic, retain) EKEventStore *eventStore;

@end
