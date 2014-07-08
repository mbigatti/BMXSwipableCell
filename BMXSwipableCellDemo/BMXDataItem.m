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
    if (_firstName.length != 0) {
        return [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
    } else {
        return _lastName;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"(%lu) %@/%@", (unsigned long)_userId, _firstName, _lastName];
}

@end
