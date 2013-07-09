//
//  IPHTTPConnection.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 7/10/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPHTTPConnection.h"
#import "IPServer.h"
#import "IPEngine.h"
#import "HTTPLogging.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"

static int const httpLogLevel = HTTP_LOG_LEVEL_WARN;

@implementation IPHTTPConnection

/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResponse is a wrapper for an NSData object, and may be used to send a custom response.
 **/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	HTTPLogTrace();

	NSString *filePath = [self filePathForURI:path allowDirectory:NO];
	BOOL isDir = NO;
	
	if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
        if ([[filePath pathExtension] isEqualToString:@"php"]) {
            IPEngine *engine = [IPServer sharedServer].engine;
            __block NSData *data = nil;
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            [engine enqueueFilePath:filePath completion:^(NSData *buffer){
                data = buffer;
                dispatch_semaphore_signal(sem);
            }];
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            return [[HTTPDataResponse alloc] initWithData:data];
        } else {
            return [[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self];
        }
	}
	
	return nil;
}

@end
