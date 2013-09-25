//
//  BMXSwipableCellContentView.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXSwipableCellContentView.h"
#import "BMXSwipableCell.h"

@interface BMXSwipableCellContentView ()

@property (nonatomic, strong) BMXSwipableCell *cell;

@end

@implementation BMXSwipableCellContentView

- (id)initWithFrame:(CGRect)frame cell:(BMXSwipableCell *)cell
{
    self = [super initWithFrame:frame];
    if (self) {
        self.cell = cell;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.cell cellTapped];
}

@end
