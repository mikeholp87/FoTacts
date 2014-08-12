//
//  FoTacts_Meetup.m
//  FoTacts
//
//  Created by Michael Holp on 2/20/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "FoTacts_Meetup.h"

#define kGeoCodingString @"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true&language=us"

@implementation FoTacts_Meetup
@synthesize mapView, locationManager, geocoder, addressLbl, userCoordinate, picture, locationField, emailField, twitterField, timePicker, timeField, phoneField, actionSheet, segControl;

//Constants for view manipulation during keyboard usage
static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3f;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2f;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8f;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;

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
	[self setUserLocation];
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(backToMain)];
    [self.navigationItem setLeftBarButtonItem:backBtn];
}

- (void)viewWillAppear:(BOOL)animated
{
    userInfo = [[NSUserDefaults alloc] init];
    imagePath = [userInfo objectForKey:@"user_photo"];
    meetingTime = @"";
}

- (void)backToMain
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)setUserLocation
{
    mapView.showsUserLocation = YES;
    mapView.delegate = self;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    userCoordinate = locationManager.location.coordinate;
    [mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    [mapView setCenterCoordinate:userCoordinate];
    
    MKCoordinateRegion region;
    region.center.latitude = userCoordinate.latitude;
    region.center.longitude = userCoordinate.longitude;
    region.span.latitudeDelta = 1;
    region.span.longitudeDelta = 1;
    region = [mapView regionThatFits:region];
    [mapView setRegion:region animated:YES];
    
    [self fetchReverseGeocodeAddress:userCoordinate.latitude withLongitude:userCoordinate.longitude];
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
	}
	
    static NSString *identifier = @"RoutePinAnnotation";
    
	if ([annotation isKindOfClass:[MKPinAnnotationView class]]) {
        MKAnnotationView *pinAnnotation = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if(!pinAnnotation) {
            pinAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        }
        
        pinAnnotation.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        pinAnnotation.draggable = NO;
        pinAnnotation.enabled = YES;
        pinAnnotation.canShowCallout = NO;
        
        return pinAnnotation;
	} else {
		return [mapView viewForAnnotation:mapView.userLocation];
	}
}

-(void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views
{
    MKAnnotationView *ulv = [mv viewForAnnotation:mv.userLocation];
    ulv.canShowCallout = NO;
    
    id <MKAnnotation> mp = [mv.annotations objectAtIndex:0];
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate], 1000, 1000);
	[mv setRegion:region animated:YES];
	[mv selectAnnotation:mp animated:YES];
}

- (void)fetchReverseGeocodeAddress:(float)pdblLatitude withLongitude:(float)pdblLongitude {
    geocoder = [[CLGeocoder alloc] init];
    CLLocation *newLocation = [[CLLocation alloc]initWithLatitude:pdblLatitude longitude:pdblLongitude];
    
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"Geocode failed with error: %@", error);
            return;
        }
        
        if (placemarks && placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            
            NSDictionary *addressDictionary = placemark.addressDictionary;
            //NSLog(@"%@", addressDictionary);
            NSString *address = [addressDictionary objectForKey:@"Name"];
            
            [self performSelectorInBackground:@selector(setAddress:) withObject:address];
        }
    }];
}

-(void)setAddress:(NSString *)address
{
    addressLbl.text = address;
    NSLog(@"%@", address);
}

- (void)fetchForwardGeocodeAddress:(NSString *)address withCompletionHanlder:(ForwardGeoCompletionBlock)completion {
    geocoder = [[CLGeocoder alloc] init];
    CLGeocodeCompletionHandler completionHandler = ^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"error finding placemarks: %@", [error localizedDescription]);
        }
        if (placemarks) {
            [placemarks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CLPlacemark *placemark = (CLPlacemark *)obj;
                if (completion) {
                    completion(placemark.location.coordinate);
                }
                *stop = YES;
            }];
        }
    };
    
    [geocoder geocodeAddressString:address completionHandler:completionHandler];
}

- (void)sendTweet
{
    if([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            if([locationField.text isEqualToString:@""]){
                if([meetingTime isEqualToString:@""])
                    [tweetSheet setInitialText:[NSString stringWithFormat:@"@%@ This is what I look like today. Let's meet at %@. @FoTacts", twitterField.text, addressLbl.text]];
                else
                    [tweetSheet setInitialText:[NSString stringWithFormat:@"@%@ This is what I look like today. Let's meet at %@, %@. @FoTacts", twitterField.text, addressLbl.text, meetingTime]];
            }else{
                if([meetingTime isEqualToString:@""])
                    [tweetSheet setInitialText:[NSString stringWithFormat:@"@%@ This is what I look like today. Let's meet at %@. @FoTacts", twitterField.text, locationField.text]];
                else
                    [tweetSheet setInitialText:[NSString stringWithFormat:@"@%@ This is what I look like today. Let's meet at %@, %@ @FoTacts", twitterField.text, locationField.text, meetingTime]];
            }
            [tweetSheet addImage:picture];
            [tweetSheet addURL:[NSURL URLWithString:@"www.fotacts.co"]];
            
            [tweetSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
                switch (result) {
                    case SLComposeViewControllerResultCancelled:
                        NSLog(@"Post Canceled");
                        break;
                    case SLComposeViewControllerResultDone:
                        NSLog(@"Post Sucessful");
                        [self goToSucess];
                        break;
                        
                    default:
                        break;
                }
            }];
            
            [self presentViewController:tweetSheet animated:YES completion:nil];
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }else{
        NSURL *url = [NSURL URLWithString:@"www.fotacts.co"];
        SHKItem *item = [SHKItem URL:url title:@"FoTacts is changing how you confirm meetings, schedule follow ups and make better connections. Download the app for free now! #FoTacts"];
        [SHKTwitter shareItem:item];
    }
}

- (void)postStatus
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
                
                [controller dismissViewControllerAnimated:YES completion:nil];
            };
            controller.completionHandler = myBlock;
            
            [controller setInitialText:@"FoTacts is changing how you confirm meetings, schedule follow ups and make better connections. Download the app for free now!"];
            [controller addURL:[NSURL URLWithString:@"www.fotacts.co"]];
            [controller addImage:picture];
            
            [self presentViewController:controller animated:YES completion:nil];
            
        }
        else{
            NSLog(@"Unavailable");
        }
    }else{
        NSURL *url = [NSURL URLWithString:@"www.fotacts.co"];
        SHKItem *item = [SHKItem URL:url title:@"NFoTacts is changing how you confirm meetings, schedule follow ups and make better connections. Download the app for free now!"];
        [SHKFacebook shareItem:item];
    }
}

- (void)sendSMS
{
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        
        if([self validatePhone:phoneField.text]){
            picker.recipients = [NSArray arrayWithObject:contact_phone];
            NSURL *url = [NSURL URLWithString:@"www.fotacts.co"];
            if([locationField.text isEqualToString:@""]){
                picker.body = [NSString stringWithFormat:@"I use FoTacts to confirm meetings. Here's what I look like today. Let's meetup at %@, %@. Download the free app at %@.", addressLbl.text, timeField.text, url];
            }else{
                picker.body = [NSString stringWithFormat:@"I use FoTacts to confirm meetings. Here's what I look like today. Let's meetup at %@, %@. Download the free app at %@.", addressLbl.text, timeField.text, url];
            }
            
            [self presentViewController:picker animated:YES completion:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"FoTacts | Email" message:@"This person does not have a valid email address." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Send" message:@"FoTacts was unable to deliver your text message at this time." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)sendEmail
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        
        if([self validateEmail:emailField.text]){
            NSURL *url = [NSURL URLWithString:@"www.fotacts.co"];
            [controller setToRecipients:[NSArray arrayWithObject:contact_email]];
            [controller setSubject:@"FoTacts Meeting Details"];
            [controller addAttachmentData:UIImageJPEGRepresentation(picture, 1) mimeType:@"image/png" fileName:@"picture.png"];
            if([locationField.text isEqualToString:@""]){
                [controller setMessageBody:[NSString stringWithFormat:@"This is what I look like today. Let's meet at %@. Download FoTacts for free at %@.", addressLbl.text, url] isHTML:YES];
            }else{
                [controller setMessageBody:[NSString stringWithFormat:@"This is what I look like today. Let's meet at %@, %@, Download FoTacts for free at %@.", addressLbl.text, timeField.text, url] isHTML:YES];
            }
            
            [self presentViewController:controller animated:YES completion:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"FoTacts | Email" message:@"This person does not have a valid email address." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
}

#pragma mark - Send SMS/Email
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    if(result == MessageComposeResultFailed){
        [[[UIAlertView alloc] initWithTitle:@"FoTacts Error" message:@"There was a problem sending your text message." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else if(result == MessageComposeResultCancelled){
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        NSLog(@"Result: sent");
        [self dismissViewControllerAnimated:YES completion:^{
            [self goToSucess];
        }];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
    if(result == MFMailComposeResultFailed){
        [[[UIAlertView alloc] initWithTitle:@"FoTacts Error" message:@"There was a problem sending your email." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else if(result == MFMailComposeResultCancelled){
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        NSLog(@"Result: sent");
        [self dismissViewControllerAnimated:YES completion:^{
            [self goToSucess];
        }];
    }
}

- (void)goToSucess
{
    UIViewController *success = [self.storyboard instantiateViewControllerWithIdentifier:@"FoTacts_Success"];
    [self.navigationController pushViewController:success animated:YES];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
    [self displayPerson:person];
    [self dismissViewControllerAnimated:YES completion:^{
        emailField.text = contact_email;
    }];
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

-(void)displayPerson:(ABRecordRef)person
{
    first_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    last_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    ABMultiValueRef emailAddresses = ABRecordCopyValue(person, kABPersonEmailProperty);
    
    if(ABMultiValueGetCount(emailAddresses)>0)
        contact_email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emailAddresses, 0);
    else
        contact_email = @"";
}

- (void)displayContactList
{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (UIToolbar *)keyboardToolBar {
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    segControl = [[UISegmentedControl alloc] initWithItems:@[@"Previous", @"Next"]];
    [segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    segControl.momentary = YES;
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)];
    
    [segControl addTarget:self action:@selector(nextPrevious) forControlEvents:(UIControlEventValueChanged)];
    [segControl setEnabled:NO forSegmentAtIndex:0];
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithCustomView:segControl];
    
    NSArray *itemsArray = @[nextButton, flexibleItem, done];
    
    [toolbar setItems:itemsArray];
    
    return toolbar;
}

- (void)nextPrevious
{
    switch([segControl selectedSegmentIndex]) {
        case 0:{
            if(timeField.isEditing) [locationField becomeFirstResponder];
            else if(timeField.isHighlighted){
                [self pickerDone:self];
                [timeField becomeFirstResponder];
            }
            else if(emailField.isEditing) [phoneField becomeFirstResponder];
            else if(twitterField.isEditing) [emailField becomeFirstResponder];
        }
            break;
        case 1:{
            if(locationField.isEditing){
                [timeField setHighlighted:YES];
                [timeField becomeFirstResponder];
            }
            else if(timeField.isEditing) [phoneField becomeFirstResponder];
            else if(phoneField.isEditing) [emailField becomeFirstResponder];
            else if(emailField.isEditing) [twitterField becomeFirstResponder];
            
        }
            break;
    }
}

#pragma mark UItextField Handling
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect textFieldRect  = [self.view.window convertRect:textField.bounds fromView:textField];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds fromView:self.view];
    CGFloat midline = textFieldRect.origin.y + 0.5f * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    if (heightFraction < 0.0)
    {
        heightFraction = 0.0f;
    }
    else if (heightFraction > 1.0)
    {
        heightFraction = 1.0f;
    }
    UIInterfaceOrientation orientation =[[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        animatedDistance = floorf(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    }
    else
    {
        animatedDistance = floorf(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.inputAccessoryView = [self keyboardToolBar];
    if (textField == locationField){
        [segControl setEnabled:NO forSegmentAtIndex:0];
        [segControl setEnabled:YES forSegmentAtIndex:1];
    }else if (textField == timeField){
        [self dismissKeyboard];
        [self createActionSheet];
        timePicker.hidden = NO;
        
        [segControl setEnabled:YES forSegmentAtIndex:0];
        [segControl setEnabled:YES forSegmentAtIndex:1];
        
        return NO;
    }else if (textField == twitterField){
        [segControl setEnabled:YES forSegmentAtIndex:0];
        [segControl setEnabled:NO forSegmentAtIndex:1];
    }else{
        [segControl setEnabled:YES forSegmentAtIndex:0];
        [segControl setEnabled:YES forSegmentAtIndex:1];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y += animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == phoneField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        newString = [[newString componentsSeparatedByCharactersInSet:
                      [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                     componentsJoinedByString:@""];
        newString = [self formatPhoneNumber:newString];
        
        textField.text = newString;
        return NO;
    }else{
        return YES;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self dismissKeyboard];
    
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)dismissKeyboard
{
    [phoneField resignFirstResponder];
    [emailField resignFirstResponder];
    [twitterField resignFirstResponder];
    [timeField resignFirstResponder];
    [locationField resignFirstResponder];
    if (timePicker && !timePicker.hidden) {
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [outputFormatter setDateFormat:@"MM/dd/yy h:mm a"];
        NSString *displayed_date = [outputFormatter stringFromDate:timePicker.date];
        [timeField setText:[NSString stringWithFormat:@"%@", displayed_date]];
        [timePicker setHidden:YES];
        
        [outputFormatter setDateFormat:@"h:mm a"];
        meetingTime = [outputFormatter stringFromDate:timePicker.date];
    }
}

-(BOOL)validateEmail:(NSString*)emailString
{
    NSString *regExPattern = @"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$";
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString options:0 range:NSMakeRange(0, [emailString length])];
    NSLog(@"%i", regExMatches);
    if (regExMatches == 0) {
        return NO;
    } else
        return YES;
}

-(BOOL)validatePhone:(NSString*)phoneString
{
    NSString *regExPattern = @"^(?:(?:\\+?1\\s*(?:[.-]\\s*)?)?(?:\\(\\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\\s*\\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\\s*(?:[.-]\\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\\s*(?:[.-]\\s*)?([0-9]{4})(?:\\s*(?:#|x\\.?|ext\\.?|extension)\\s*(\\d+))?$";
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:phoneString options:0 range:NSMakeRange(0, [phoneString length])];
    NSLog(@"%i", regExMatches);
    if (regExMatches == 0) {
        return NO;
    } else
        return YES;
}

- (IBAction)sendPhoto:(id)sender
{
    if(![emailField.text isEqualToString:@""]){
        contact_email = emailField.text;
        [self sendEmail];
    }else if(![twitterField.text isEqualToString:@""]){
        twitterAcct = twitterField.text;
        [self sendTweet];
    }
}

#pragma mark - HTTP REQUEST
- (void)requestFinished:(ASIHTTPRequest *)local_request
{
    NSString *jsonString = [local_request responseString];
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject = [parser objectWithString:jsonString error:NULL];
    
    NSMutableDictionary *resultsObject = [[jsonObject objectForKey:@"results"] objectAtIndex:0];
    currentAddress = [resultsObject objectForKey:@"formatted_address"];
    currentAddress = [currentAddress substringToIndex:[currentAddress length] - 11];
}

- (void)requestFailed:(ASIHTTPRequest *)local_request{
    NSError *local_error = [local_request error];
    NSLog(@"%@",local_error.localizedDescription);
}

- (IBAction)showContacts:(id)sender
{
    [self displayContactList];
}

- (IBAction)clearTime:(id)sender
{
    timeField.text = @"";
}

-(NSString *)formatPhoneNumber:(NSString*)strippedString{
    NSString *areaCode = [[NSString alloc] init];
    NSString *firstThree = [[NSString alloc] init];
    NSString *lastFour = [[NSString alloc] init];
    
    while (strippedString.length>10) {
        strippedString = [strippedString substringToIndex:10];
    }
    if(strippedString.length<7 && strippedString.length>3){
        areaCode = [strippedString substringToIndex:3];
        firstThree = [strippedString substringFromIndex:3];
        return [NSString stringWithFormat:@"(%@) %@",areaCode,firstThree];
    }
    else if (strippedString.length>=7){
        areaCode = [strippedString substringToIndex:3];
        firstThree = [strippedString substringFromIndex:3];
        lastFour = [firstThree substringFromIndex:3];
        firstThree = [firstThree substringToIndex:3];
        return [NSString stringWithFormat:@"(%@) %@-%@",areaCode,firstThree,lastFour];
    }
    else{
        return strippedString;
    }
}

- (void)createActionSheet {
    actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.clipsToBounds = YES;
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    pickerToolbar.barStyle = UIBarStyleBlackOpaque;
    [pickerToolbar sizeToFit];
    
    segControl = [[UISegmentedControl alloc] initWithItems:@[@"Previous", @"Next"]];
    [segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    segControl.momentary = YES;
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    [segControl addTarget:self action:@selector(nextPrevious) forControlEvents:(UIControlEventValueChanged)];
    
    //UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithCustomView:segControl];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerDone:)];
    
    //NSArray *itemsArray = @[nextButton, flexibleItem, done];
    NSArray *itemsArray = @[flexibleItem, done];
    
    [pickerToolbar setItems:itemsArray];
    
    [actionSheet addSubview:pickerToolbar];
    
    timePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 44.0, 320.0, 216.0)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerDone:)];
    [timePicker addGestureRecognizer:tap];
    
    [actionSheet addSubview:timePicker];
    [actionSheet showInView:self.view];
    [actionSheet setBounds:CGRectMake(0,0,320,550)];
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    
    timePicker.hidden = YES;
}

- (void)sendLocalNotification:(NSDate *)date
{
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    
    // Notification details
    localNotif.fireDate = date;
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.alertAction = @"View";
    if([locationField.text isEqualToString:@""])
        localNotif.alertBody = [NSString stringWithFormat:@"%@", addressLbl.text];
    else
        localNotif.alertBody = [NSString stringWithFormat:@"%@", locationField.text];
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 0;
    
    // Schedule the notification
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

- (void)pickerDone:(id)sender
{
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [outputFormatter setDateFormat:@"MM/dd/yy h:mm a"];
    NSString *displayed_date = [outputFormatter stringFromDate:[timePicker date]];
    [timeField setText:[NSString stringWithFormat:@"%@", displayed_date]];
    [self sendLocalNotification:self.timePicker.date];
}

@end
