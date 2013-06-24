//
//  IPBenchmark.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/10/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPBenchmark : NSObject

- (id)initWithDestinationDirectory:(NSString *)destination;
- (NSString *)benchmarkCodeWithRepeat:(NSUInteger)repeats;

@end
