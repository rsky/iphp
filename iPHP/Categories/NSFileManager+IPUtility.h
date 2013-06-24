//
//  NSFileManager+IPUtility.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/13/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (IPUtility)

- (NSString *)userDomainPathForDirectory:(NSSearchPathDirectory)directory;

@end
