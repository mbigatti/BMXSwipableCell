//
//  UITableViewCell+ConfigureCell.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 01/10/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "UITableViewCell+ConfigureCell.h"
#import "BMXDataItem.h"

@implementation UITableViewCell (ConfigureCell)

- (void)configureCellForItem:(BMXDataItem*)item
{
    //
    // configure cell contents
    //
    self.textLabel.text = [item fullName];
    self.detailTextLabel.text = [NSString stringWithFormat: @"%lu", (unsigned long)item.userId];
    
    //
    // selected background view
    //
    CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.bounds),  CGRectGetHeight(self.bounds));
    self.selectedBackgroundView = [[UIView alloc] initWithFrame: rect];
    self.selectedBackgroundView.backgroundColor = BACKGROUND_COLOR_1;
    
}

@end
