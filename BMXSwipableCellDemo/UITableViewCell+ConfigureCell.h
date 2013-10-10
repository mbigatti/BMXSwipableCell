//
//  UITableViewCell+ConfigureCell.h
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 01/10/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BMXDataItem;

@interface UITableViewCell (ConfigureCell)

- (void)configureCellForItem:(BMXDataItem*)item;

@end
