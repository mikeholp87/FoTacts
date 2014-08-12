//
//  FoTags_Photo.h
//  FoTacts
//
//  Created by Mike Holp on 1/31/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Social/Social.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import "FoTacts_Meetup.h"

@interface FoTacts_Photo : UIViewController<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    NSUserDefaults *userInfo;
    NSString *contact_name;
    NSString *contact_phone;
    NSString *contact_email;
    NSString *first_name;
    NSString *last_name;
    NSString *sendType;
    
    bool newMedia;
}

@property(nonatomic,retain) IBOutlet UIImageView *photoView;
@property(nonatomic,retain) UIImage *picture;

@end
