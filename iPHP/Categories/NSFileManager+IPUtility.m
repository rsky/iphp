//
//  NSFileManager+IPUtility.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/13/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "NSFileManager+IPUtility.h"

@implementation NSFileManager (IPUtility)

- (NSString *)userDomainPathForDirectory:(NSSearchPathDirectory)directory
{
    return [[[self URLsForDirectory:directory inDomains:NSUserDomainMask] lastObject] path];
}

@end
