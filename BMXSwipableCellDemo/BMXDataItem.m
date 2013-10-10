//
//  BMXDataItem.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 10/10/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXDataItem.h"

@implementation BMXDataItem

- (NSString*)fullName
{
    return [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"(%d) %@/%@", _userId, _firstName, _lastName];
}

@end
