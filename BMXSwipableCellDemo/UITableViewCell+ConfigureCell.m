//
//  UITableViewCell+ConfigureCell.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 01/10/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "UITableViewCell+ConfigureCell.h"

@implementation UITableViewCell (ConfigureCell)

- (void)configureCellForItem:(NSDate*)date
{
    //
    // configure cell contents
    //
    self.textLabel.text = [date description];
    self.detailTextLabel.text = [NSString stringWithFormat: @"%f", [date timeIntervalSince1970]];
    
    //
    // selected background view
    //
    CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.bounds),  CGRectGetHeight(self.bounds));
    self.selectedBackgroundView = [[UIView alloc] initWithFrame: rect];
    self.selectedBackgroundView.backgroundColor = BACKGROUND_COLOR_1;
    
}

@end
