//
//  BMXDataItem.h
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 10/10/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMXDataItem : NSObject

@property (nonatomic, retain) NSString *firstName;

@property (nonatomic, retain)NSString *lastName;

@property (nonatomic, assign)NSUInteger userId;

- (NSString*)fullName;

@end
