//
//  FoTacts_Meetup.h
//  FoTacts
//
//  Created by Michael Holp on 2/20/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MessageUI/MessageUI.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <Social/Social.h>
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "SHKTwitter.h"
#import "SHKFacebook.h"

typedef void (^ForwardGeoCompletionBlock)(CLLocationCoordinate2D coords);

@interface FoTacts_Meetup : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, ABPeoplePickerNavigationControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UITextFieldDelegate, CLLocationManagerDelegate, UIActionSheetDelegate, MKMapViewDelegate>
{
    NSUserDefaults *userInfo;
    NSString *contact_name;
    NSString *first_name;
    NSString *last_name;
    NSString *sendType;
    NSString *contact_phone;
    NSString *contact_email;
    NSString *facebookAcct;
    NSString *twitterAcct;
    NSString *imagePath;
    NSString *fileName;
    NSString *currentAddress;
    NSString *meetingTime;
    NSString *alertText;
    NSDate *alertDate;
    
    CGFloat animatedDistance;
}

@property(nonatomic,retain) IBOutlet MKMapView *mapView;
@property(nonatomic,retain) IBOutlet UILabel *addressLbl;
@property(nonatomic,retain) IBOutlet UITextField *locationField;
@property(nonatomic,retain) IBOutlet UITextField *phoneField;
@property(nonatomic,retain) IBOutlet UITextField *emailField;
@property(nonatomic,retain) IBOutlet UITextField *twitterField;
@property(nonatomic,retain) IBOutlet UITextField *timeField;
@property(nonatomic,retain) CLLocationManager *locationManager;
@property(nonatomic,retain) CLGeocoder *geocoder;

@property(nonatomic,retain) UISegmentedControl *segControl;
@property(nonatomic,retain) UIDatePicker *timePicker;
@property(nonatomic,retain) UIActionSheet *actionSheet;
@property(nonatomic,retain) UIImage *picture;
@property(assign) CLLocationCoordinate2D userCoordinate;

@end
