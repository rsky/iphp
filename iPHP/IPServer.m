//
//  IPServer.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 7/9/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPServer.h"
#import "HTTPServer.h"
#import "IPEngine.h"
#import "IPHTTPConnection.h"

static IPServer *sharedServer = nil;

static UInt16 const defaultPort = 1980;

@implementation IPServer

+ (IPServer *)sharedServer
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [self new];
    });
    return sharedServer;
}

- (id)init
{
    self = [super init];
    if (self) {
        _engine = [IPEngine sharedEngine];
        _httpServer = [HTTPServer new];
        _port = defaultPort;
        [self configure];
    }
    return self;
}

- (void)configure
{
    _httpServer.documentRoot = [[[NSBundle mainBundle] resourcePath]
                                stringByAppendingPathComponent:@"Web"];
    _httpServer.type = @"_http._.tcp";
    _httpServer.port = _port;
    _httpServer.connectionClass = [IPHTTPConnection class];
}

- (BOOL)start
{
    if (_started) {
        NSLog(@"HTTP server is already started.");
        return NO;
    }

    NSError *error = nil;
    _started = [_httpServer start:&error];
    if (!_started) {
        NSLog(@"Cannot start HTTP server: %@", error);
    }
    return _started;
}

- (void)stop
{
    [_httpServer stop];
    _started = NO;
}

@end
