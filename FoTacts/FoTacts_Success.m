//
//  FoTacts_Success.m
//  FoTacts
//
//  Created by Michael Holp on 2/23/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "FoTacts_Success.h"

@implementation FoTacts_Success

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
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(backToMain)];
    [self.navigationItem setLeftBarButtonItem:backBtn];
}

- (void)backToMain
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)showAppStore:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/dude-wheres-my-car/id585917773?mt=8"]];
}

@end
