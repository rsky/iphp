//
//  IPEngine.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/9/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sapi/embed/php_embed.h"

@class IPEngine;

@interface IPEngine : NSObject

@property (nonatomic, readonly, getter = getBuffer) NSData *buffer;
@property (nonatomic, strong) void (^onFlushBuffer)(IPEngine __weak *);

+ (IPEngine *)sharedEngine;
- (void)restart;
- (void)gc;
- (void)clearBuffer;
- (void)flushBuffer;
- (void)enqueueCode:(NSString *)code completion:(void (^)(NSData *))completion;

@end

const char *iphp_error_type_to_string(int type);
