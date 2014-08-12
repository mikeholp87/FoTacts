//
//  FoTacts_Events.m
//  FoTacts
//
//  Created by Michael Holp on 2/9/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "FoTacts_Events.h"

@implementation FoTacts_Events
@synthesize infoTable, eventStore, eventsList, eventsDict, defaultCalendar, detailViewController;

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
}

- (void)viewWillAppear:(BOOL)animated
{
	[infoTable deselectRowAtIndexPath:infoTable.indexPathForSelectedRow animated:NO];
    
    // Initialize an event store object with the init method. Initilize the array for events.
	self.eventStore = [[EKEventStore alloc] init];
    
	self.eventsList = [[NSMutableArray alloc] initWithArray:0];
    
    self.eventsDict = [[NSMutableDictionary alloc] init];
	
	// Get the default calendar from store.
	self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
	
	//	Create an Add button
	UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd target:self action:@selector(addEvent:)];
	self.navigationItem.rightBarButtonItem = addButtonItem;
	
	self.navigationController.delegate = self;
	
	// Fetch today's event on selected calendar and put them into the eventsList array
	[self.eventsList addObjectsFromArray:[self fetchEventsForToday]];
    
	[infoTable reloadData];
}

#pragma mark -
#pragma mark Table view data source

// Fetching events happening in the next 24 hours with a predicate, limiting to the default calendar
- (NSArray *)fetchEventsForToday
{
    NSArray *events = [[NSArray alloc] initWithArray:0];
    
    NSDate *startDate = [NSDate date];
    
    // endDate is 1 day = 60*60*24 seconds = 86400 seconds from startDate
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:345600];
    
    // Create the predicate. Pass it the default calendar.
    NSArray *calendarArray = [NSArray arrayWithObject:defaultCalendar];
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:calendarArray];
    
    // Fetch all events that match the predicate.
    events = [self.eventStore eventsMatchingPredicate:predicate];
    
    return events;
}

#pragma mark -
#pragma mark Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return eventsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	static NSString *CellIdentifier = @"Cell";
	
	// Add disclosure triangle to cell
	UITableViewCellAccessoryType editableCellAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}
	
	cell.accessoryType = editableCellAccessoryType;
    
    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.row;
    
    UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addFavorite:)];
    tapped.numberOfTapsRequired = 1;
    [cell.imageView addGestureRecognizer:tapped];
    
	cell.textLabel.font = [UIFont boldSystemFontOfSize:13.0];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0];
	cell.textLabel.text = [[self.eventsList objectAtIndex:indexPath.row] title];
    //cell.detailTextLabel.text = [[self.eventsList objectAtIndex:indexPath.row] location];
    //cell.detailTextLabel.text = [[[[self.eventsList objectAtIndex:indexPath.row] attendees] objectAtIndex:1] name];
    cell.imageView.image = [UIImage imageNamed:@"star_off.png"];
    
	return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Upon selecting an event, create an EKEventViewController to display the event.
	self.detailViewController = [[EKEventViewController alloc] initWithNibName:nil bundle:nil];
	detailViewController.event = [self.eventsList objectAtIndex:indexPath.row];
	
	// Allow event editing.
	detailViewController.allowsEditing = YES;
	
	//	Push detailViewController onto the navigation controller stack
	//	If the underlying event gets deleted, detailViewController will remove itself from
	//	the stack and clear its event property.
	[self.navigationController pushViewController:detailViewController animated:YES];
    
}

#pragma mark -
#pragma mark Navigation Controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	// if we are navigating back to the rootViewController, and the detailViewController's event
	// has been deleted -  will title being NULL, then remove the events from the eventsList
	// and reload the table view. This takes care of reloading the table view after adding an event too.
	if (viewController == self && self.detailViewController.event.title == NULL) {
		[self.eventsList removeObject:self.detailViewController.event];
		[infoTable reloadData];
	}
}

- (void)addFavorite:(id)sender
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    UITableViewCell *cell = [infoTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:gesture.view.tag inSection:0]];
    
    NSLog(@"%@", eventsList);
    
    for(int i=0; i<[[[self.eventsList objectAtIndex:gesture.view.tag] attendees] count]; i++)
    {
        [eventsDict setObject:[NSArray arrayWithObjects:cell.detailTextLabel.text, [[[[self.eventsList objectAtIndex:gesture.view.tag] attendees] objectAtIndex:i] name], nil] forKey:cell.textLabel.text];
    }
    
    if(cell.imageView.image == [UIImage imageNamed:@"star_on.png"]){
        cell.imageView.image = [UIImage imageNamed:@"star_off.png"];
        if(eventsDict != nil){
            [eventsDict removeObjectForKey:cell.detailTextLabel.text];
        }
    }else{
        cell.imageView.image = [UIImage imageNamed:@"star_on.png"];
        //[eventsDict setObject:[NSArray arrayWithObjects:cell.detailTextLabel.text, [[[[self.eventsList objectAtIndex:gesture.view.tag] attendees] objectAtIndex:1] name], nil] forKey:cell.textLabel.text];
    }
    
    NSLog(@"%@", eventsDict);
}


#pragma mark -
#pragma mark Add a new event

// If event is nil, a new event is created and added to the specified event store. New events are
// added to the default calendar. An exception is raised if set to an event that is not in the
// specified event store.
- (void)addEvent:(id)sender
{
	// When add button is pushed, create an EKEventEditViewController to display the event.
	EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
	
	// set the addController's event store to the current event store.
	addController.eventStore = self.eventStore;
	
	// present EventsAddViewController as a modal view controller
	[self presentModalViewController:addController animated:YES];
	
	addController.editViewDelegate = self;
}


#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{	
	NSError *error = nil;
	EKEvent *thisEvent = controller.event;
	
	switch (action) {
		case EKEventEditViewActionCanceled:
			// Edit action canceled, do nothing.
			break;
			
		case EKEventEditViewActionSaved:
			// When user hit "Done" button, save the newly created event to the event store,
			// and reload table view.
			// If the new event is being added to the default calendar, then update its
			// eventsList.
			if (self.defaultCalendar ==  thisEvent.calendar) {
				[self.eventsList addObject:thisEvent];
			}
			[controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
			[infoTable reloadData];
			break;
			
		case EKEventEditViewActionDeleted:
			// When deleting an event, remove the event from the event store,
			// and reload table view.
			// If deleting an event from the currenly default calendar, then update its
			// eventsList.
			if (self.defaultCalendar ==  thisEvent.calendar) {
				[self.eventsList removeObject:thisEvent];
			}
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			[infoTable reloadData];
			break;
			
		default:
			break;
	}
	// Dismiss the modal view controller
	[controller dismissModalViewControllerAnimated:YES];	
}

// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller
{
	EKCalendar *calendarForEdit = self.defaultCalendar;
	return calendarForEdit;
}

@end
