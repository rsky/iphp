//
//  IPBenchmark.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/10/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPBenchmark.h"

@implementation IPBenchmark {
    NSString *_destination;
}

- (id)initWithDestinationDirectory:(NSString *)destination
{
    self = [self init];
    if (self) {
        _destination = destination;
    }
    return self;
}

- (NSString *)benchmarkCodeWithRepeat:(NSUInteger)repeats
{
    NSString *source = [[NSBundle mainBundle] pathForResource:@"source" ofType:@"jpeg"];
    return [NSString stringWithFormat:
            @"$im = imagecreatefromjpeg(%@);\n"
            @"$start = microtime(true);\n"
            @"for ($i = 0; $i < %u; $i++) {\n"
            @"ob_start(); imagejpeg($im); ob_end_clean();\n"
            @"}\n"
            @"$end = microtime(true);\n"
            @"var_dump($end - $start);",
            [self quotePath:source], repeats];
}

- (NSString *)quotePath:(NSString *)path
{
    return [NSString stringWithFormat:@"'%s'", [path fileSystemRepresentation]];
}

@end
