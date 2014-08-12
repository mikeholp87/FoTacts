//
//  FoTacts_Meetup.m
//  FoTacts
//
//  Created by Michael Holp on 2/20/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "FoTacts_Meetup.h"

#define kGeoCodingString @"http://maps.google.com/maps/geo?q=%f,%f&output=csv"

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
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    imagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"userPhoto_%.08f.png",[[NSDate date] timeIntervalSince1970]]];
    
    NSLog(@"%@", imagePath);
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
    
    addressLbl.text = [self getAddress:userCoordinate.latitude withLongitude:userCoordinate.longitude];
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

-(NSString *)getAddress:(double)pdblLatitude withLongitude:(double)pdblLongitude
{
    NSString *urlString = [NSString stringWithFormat:kGeoCodingString,pdblLatitude, pdblLongitude];
    NSError *error;
    NSString *locationString = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSASCIIStringEncoding error:&error];
    locationString = [locationString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    locationString = [locationString substringFromIndex:6];
    return [locationString substringToIndex:[locationString length] - 11];
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
                [tweetSheet setInitialText:[NSString stringWithFormat:@"We met earlier, would you like to meetup at %@? @%@ @FoTacts", addressLbl.text, twitterField.text]];
            }else{
                [tweetSheet setInitialText:[NSString stringWithFormat:@"We met earlier, would you like to meetup at %@? @%@ @FoTacts", locationField.text, twitterField.text]];
            }
            [tweetSheet addImage:picture];
            [tweetSheet addURL:[NSURL URLWithString:@"www.fotacts.com"]];
            
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
        NSURL *url = [NSURL URLWithString:@"www.fotacts.com"];
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
            [controller addURL:[NSURL URLWithString:@"www.fotacts.com"]];
            [controller addImage:picture];
            
            [self presentViewController:controller animated:YES completion:nil];
            
        }
        else{
            NSLog(@"Unavailable");
        }
    }else{
        NSURL *url = [NSURL URLWithString:@"www.fotacts.com"];
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
            NSURL *url = [NSURL URLWithString:@"www.fotacts.com"];
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
            NSURL *url = [NSURL URLWithString:@"www.fotacts.com"];
            [controller setToRecipients:[NSArray arrayWithObject:contact_email]];
            [controller setSubject:@"Download FoTacts for free now!"];
            [controller addAttachmentData:UIImageJPEGRepresentation(picture, 1) mimeType:@"image/png" fileName:@"picture.png"];
            if([locationField.text isEqualToString:@""]){
                [controller setMessageBody:[NSString stringWithFormat:@"I use FoTacts to confirm meetings. Here's what I look like today. Let's meetup at %@, %@. Download the free app at %@.", addressLbl.text, timeField.text, url] isHTML:YES];
            }else{
                [controller setMessageBody:[NSString stringWithFormat:@"I use FoTacts to confirm meetings. Here's what I look like today. Let's meetup at %@, %@. Download the free app at %@.", addressLbl.text, timeField.text, url] isHTML:YES];
            }
            
            [self presentViewController:controller animated:YES completion:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"FoTacts | Email" message:@"This person does not have a valid email address." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Send" message:@"FoTacts was unable to deliver your email at this time." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
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
    if(result == MessageComposeResultFailed){
        [[[UIAlertView alloc] initWithTitle:@"FoTacts Error" message:@"There was a problem sending your email." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
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
        phoneField.text = [self formatPhoneNumber:contact_phone];
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
    
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person,kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phoneNumbers) > 0) {
        contact_phone = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
        contact_phone = [[contact_phone componentsSeparatedByCharactersInSet:
                          [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                         componentsJoinedByString:@""];
        if (contact_phone.length>10) {
            contact_phone = [contact_phone substringFromIndex:contact_phone.length-10];
        }
    } else {
        contact_phone = @"";
    }
    
    
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
    if(![phoneField.text isEqualToString:@""]){
        contact_phone = phoneField.text;
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://dwmcapp.com/API/fotacts_api.php"]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [NSString stringWithFormat:@"userPhoto_%.08f.jpg",[[NSDate date] timeIntervalSince1970]]]];
        
        NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:imagePath]);
        
        [request setPostValue:[[NSUUID UUID] UUIDString] forKey:@"udid"];
        [request setPostValue:fullPath forKey:@"filename"];
        [request setData:imageData withFileName:imagePath andContentType:@"image/png" forKey:@"photo"];
        [request setPostValue:@"upload_photo" forKey:@"cmd"];
        [request setUploadProgressDelegate:self];
        [request setDelegate:self];
        [request startAsynchronous];
        
        //[self uploadImage];
        
    }else if(![emailField.text isEqualToString:@""]){
        contact_email = emailField.text;
        [self sendEmail];
    }else if(![twitterField.text isEqualToString:@""]){
        twitterAcct = twitterField.text;
        [self sendTweet];
    }
}

- (void)uploadImage
{
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:imagePath]);
    
    WRRequestUpload *uploadImage = [[WRRequestUpload alloc] init];
    uploadImage.delegate = self;
    
    //for anonymous login just leave the username and password nil
    uploadImage.hostname = @"dwmcapp.com";
    uploadImage.username = @"austinpreneur";
    uploadImage.password = @"Iphone5@";
    
    //we set our data
    uploadImage.sentData = imageData;
    
    //the path needs to be absolute to the FTP root folder.
    //full URL would be ftp://xxx.xxx.xxx.xxx/space.jpg
    uploadImage.path = @"/user_photo.png";
    
    //we start the request
    [uploadImage start];
    
}

-(void)requestCompleted:(WRRequest *)request{
    NSLog(@"%@ completed!", request);
}

-(void)requestFailed:(WRRequest *)request{
    NSLog(@"%@", request.error.message);
}

-(BOOL)shouldOverwriteFileWithRequest:(WRRequest *)request{
    return YES;
}
/*
#pragma mark - HTTP REQUEST
- (void)requestFinished:(ASIHTTPRequest *)local_request
{
    NSString *jsonString = [local_request responseString];
    NSLog(@"Refresh Response String is: %@",jsonString);
    
    [self sendSMS];
}

- (void)requestFailed:(ASIHTTPRequest *)local_request
{
    NSError *local_error = [local_request error];
    NSLog(@"%@",local_error.localizedDescription);
}
*/
- (IBAction)showContacts:(id)sender
{
    [self displayContactList];
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
    localNotif.fireDate = [date dateByAddingTimeInterval:-15*60];
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
