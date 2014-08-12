//
//  MainViewCell.h
//  FoTacts
//
//  Created by Mike Holp on 2/2/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MainViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UITextView *notesView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *photo;

@end
