//
//  IPServer.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 7/9/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPServer;
@class IPEngine;

@interface IPServer : NSObject

@property (nonatomic, readonly) HTTPServer *httpServer;
@property (nonatomic, readonly) IPEngine *engine;
@property (nonatomic, readonly, getter = isStarted) BOOL started;
@property (nonatomic, readonly) UInt16 port;

+ (IPServer *)sharedServer;

- (void)configure;
- (BOOL)start;
- (void)stop;

@end
