//
//  FoTacts_Info.m
//  FoTacts
//
//  Created by Mike Holp on 1/31/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "FoTacts_Info.h"

@implementation FoTacts_Info
@synthesize firstNameField, lastNameField, emailField, phoneField, segControl, facebookButton, twitterButton, actionSheet, timePicker, datetimeLabel;

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
    
    alarmDate = [[NSUserDefaults alloc] init];
    userInfo = [[NSUserDefaults alloc] init];
    
    self.navigationController.navigationBarHidden = NO;
    
    datetimeLabel.text = [alarmDate objectForKey:@"alarm_date"];
    
    firstNameField.text = [userInfo valueForKey:@"contact_firstname"];
    lastNameField.text = [userInfo valueForKey:@"contact_lastname"];
    emailField.text = [userInfo valueForKey:@"contact_email"];
    phoneField.text = [userInfo valueForKey:@"contact_phone"];
}

- (IBAction)loginFacebook:(id)sender
{
    // Create the item to share (in this example, a url)
    NSURL *url = [NSURL URLWithString:@"www.dwmcapp.com"];
    SHKItem *item = [SHKItem URL:url title:@"Never Lose Your Car Again! Download \"Dude Where's My Car?\" for FREE!"];
    
    // Get the ShareKit action sheet
    SHKActionSheet *SKActionSheet = [SHKActionSheet actionSheetForItem:item];
    
    // Display the action sheet
    [SKActionSheet showInView:self.view];
}
 
- (IBAction)loginTwitter:(id)sender
{
    
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (IBAction)EditAlarm:(id)sender
{
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    
    CGRect pickerFrame = CGRectMake(0, 40, 0, 0);
    
    timePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    [actionSheet addSubview:timePicker];
    
    UISegmentedControl *setButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Set"]];
    setButton.momentary = YES;
    setButton.frame = CGRectMake(260.0f, 7.0f, 50.0f, 30.0f);
    setButton.segmentedControlStyle = UISegmentedControlStyleBar;
    setButton.tintColor = [UIColor blueColor];
    [setButton addTarget:self action:@selector(SetAlarm) forControlEvents:UIControlEventValueChanged];
    
    UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Close"]];
    closeButton.momentary = YES;
    closeButton.frame = CGRectMake(10.0f, 7.0f, 50.0f, 30.0f);
    closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
    closeButton.tintColor = [UIColor blackColor];
    [closeButton addTarget:self action:@selector(dismissActionSheet) forControlEvents:UIControlEventValueChanged];
    
    [actionSheet addSubview:setButton];
    [actionSheet addSubview:closeButton];
    [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
}

- (void)SetAlarm
{
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"hh:mm a"];
    [outputFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *dateString = [outputFormatter stringFromDate:self.timePicker.date];
    
    [self sendLocalNotification:self.timePicker.date];
    
    [alarmDate setObject:dateString forKey:@"alarm_date"];
    [alarmDate synchronize];
    
    datetimeLabel.text = [alarmDate objectForKey:@"alarm_date"];
    
    timePicker.hidden = YES;
}

- (void)sendLocalNotification:(NSDate *)date
{
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    
    // Notification details
    localNotif.fireDate = date;
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.alertBody = @"Would you like to take a photo?";
    localNotif.alertAction = @"Take Photo";
    localNotif.repeatInterval = NSWeekCalendarUnit;
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 0;
    
    // Schedule the notification
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

- (void)dismissActionSheet
{
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (UIToolbar *)keyboardToolBar {
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    segControl = [[UISegmentedControl alloc] initWithItems:@[@"Previous", @"Next"]];
    [segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    segControl.momentary = YES;
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *login = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard)];
    
    [segControl addTarget:self action:@selector(nextPrevious) forControlEvents:(UIControlEventValueChanged)];
    [segControl setEnabled:NO forSegmentAtIndex:0];
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithCustomView:segControl];
    
    NSArray *itemsArray = @[nextButton, flexibleItem, login];
    
    [toolbar setItems:itemsArray];
    
    return toolbar;
}

- (void)nextPrevious
{
    switch([segControl selectedSegmentIndex]) {
        case 0:{
            if(lastNameField.isEditing) [firstNameField becomeFirstResponder];
            else if(emailField.isEditing) [lastNameField becomeFirstResponder];
            else if(phoneField.isEditing) [emailField becomeFirstResponder];
        }
            break;
        case 1:{
            if(firstNameField.isEditing) [lastNameField becomeFirstResponder];
            else if(lastNameField.isEditing) [emailField becomeFirstResponder];
            else if(emailField.isEditing) [phoneField becomeFirstResponder];
            
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
    
    if (textField == firstNameField){
        [segControl setEnabled:NO forSegmentAtIndex:0];
        [segControl setEnabled:YES forSegmentAtIndex:1];
    }else if (textField == phoneField){
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
    
    [userInfo setValue:firstNameField.text forKey:@"contact_firstname"];
    [userInfo setValue:lastNameField.text forKey:@"contact_lastname"];
    [userInfo setValue:emailField.text forKey:@"contact_email"];
    [userInfo setValue:phoneField.text forKey:@"contact_phone"];
    [userInfo synchronize];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)dismissKeyboard
{
    [firstNameField resignFirstResponder];
    [lastNameField resignFirstResponder];
    [emailField resignFirstResponder];
    [phoneField resignFirstResponder];
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismissActionSheet];
    timePicker.hidden = YES;
    
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)didReceiveMemoryWarning
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
