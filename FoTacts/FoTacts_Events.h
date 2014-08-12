//
//  FoTacts_Events.h
//  FoTacts
//
//  Created by Michael Holp on 2/9/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKitUI/EventKitUI.h>
#import <EventKit/EventKit.h>

@interface FoTacts_Events : UIViewController<UINavigationControllerDelegate, EKEventViewDelegate, EKEventEditViewDelegate, EKCalendarChooserDelegate>

@property (nonatomic, retain) IBOutlet UITableView *infoTable;

@property (nonatomic, retain) EKEventStore *eventStore;
@property (nonatomic, retain) EKCalendar *defaultCalendar;
@property (nonatomic, retain) NSMutableArray *eventsList;
@property (nonatomic, retain) NSMutableDictionary *eventsDict;
@property (nonatomic, retain) EKEventViewController *detailViewController;

@end
