//
//  BMXSwipableCell.h
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMXSwipableCellContentView.h"

@interface BMXSwipableCell : UITableViewCell <UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat catchWidth;
@property (nonatomic, assign) BOOL showingBasement;

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) BMXSwipableCellContentView *scrollViewContentView;
@property (nonatomic, strong, readonly) UIView *basementView;

//
// call this to select cell
//
- (void)cellTapped;

//
// restore initial state for all cells
//
+ (void)hideBasementOfAllCells;

@end
