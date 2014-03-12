//
//  BMXSwipableCell+ConfigureCell.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXSwipableCell+ConfigureCell.h"
#import "BMXDataItem.h"

@implementation BMXSwipableCell (ConfigureCell)

- (void)configureCellForItem:(BMXDataItem*)item
{
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    CGFloat x = self.basementVisibleWidth - cellHeight * 2;

    //
    // configure cell only if not already done
    //
    if (!self.basementConfigured) {
        
        //
        // more button
        //
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.backgroundColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0f];
        moreButton.frame = CGRectMake(x, 0, cellHeight, cellHeight);
        [moreButton setTitle: @"More" forState: UIControlStateNormal];
        [moreButton setTitleColor: [UIColor yellowColor] forState: UIControlStateNormal];
        [moreButton addTarget: self
                       action: @selector(userPressedMoreButton:)
             forControlEvents: UIControlEventTouchUpInside];
        
        [self.basementView addSubview: moreButton];
        
        //
        // delete button
        //
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.backgroundColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0f];
        deleteButton.frame = CGRectMake(x + cellHeight, 0, cellHeight, cellHeight);
        [deleteButton setTitle: @"Delete" forState: UIControlStateNormal];
        [deleteButton setTitleColor: [UIColor yellowColor] forState: UIControlStateNormal];
        [deleteButton addTarget: self
                         action: @selector(userPressedDeleteButton:)
               forControlEvents: UIControlEventTouchUpInside];
        
        [self.basementView addSubview: deleteButton];
        
        //
        // mark cell basement as configured
        //
        self.basementConfigured = YES;
    }
    
    //
    // configure cell contents
    //
    self.textLabel.text = [item fullName];
    self.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)item.userId];
    
    //
    // selected background view
    //
    CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.bounds),  CGRectGetHeight(self.bounds));
    self.selectedBackgroundView = [[UIView alloc] initWithFrame: rect];
    self.selectedBackgroundView.backgroundColor = BACKGROUND_COLOR_1;
}

- (void)userPressedMoreButton:(id)sender
{
    NSLog(@"more");
}

- (void)userPressedDeleteButton:(id)sender
{
    NSLog(@"delete");
}


@end
