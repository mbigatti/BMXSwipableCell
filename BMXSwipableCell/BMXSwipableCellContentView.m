//
//  BMXSwipableCellContentView.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXSwipableCellContentView.h"
#import "BMXSwipableCell.h"

@implementation BMXSwipableCellContentView {
    BMXSwipableCell *_cell;
}

- (id)initWithFrame:(CGRect)frame cell:(BMXSwipableCell*)cell
{
    self = [super initWithFrame:frame];
    if (self) {
        _cell = cell;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_cell cellTapped];
}

@end
