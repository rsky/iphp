//
//  IPViewController.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/9/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPViewController.h"
#import "IPEngine.h"
#import "IPServer.h"
#import "IPBenchmark.h"

@interface IPViewController ()

@property (nonatomic, strong) IPEngine *phpEngine;

@end

@implementation IPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _myCode.delegate = self;
    _myCode.text = @"benchmark!";
    _phpEngine = [IPEngine sharedEngine];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [_phpEngine gc];
    [_phpEngine clearBuffer];
}

- (void)setUTF8HTML:(NSData *)html
{
    [_myWebView loadData:html MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:nil];
    _myWebView.scalesPageToFit = YES;
}

- (void)setUTF8TEXT:(NSData *)text
{
    [_myWebView loadData:text MIMEType:@"text/plain" textEncodingName:@"UTF-8" baseURL:nil];
    _myWebView.scalesPageToFit = NO;

}

- (void)hideKeyboard
{
    if ([_myCode isFirstResponder]) {
        [_myCode resignFirstResponder];
    }
}

- (void)clear:(id)sender
{
    [self hideKeyboard];
    _myCode.text = nil;
    [self setUTF8TEXT:[NSData dataWithBytes:NULL length:0]];
}

- (void)eval:(id)sender
{
    [self hideKeyboard];
    if (_myCode.text) {
        NSString *code = _myCode.text;
        if ([code isEqualToString:@"benchmark!"]) {
            [self benchmark:sender];
        } else {
            [self evaluateCode:code];
        }
    }
}

- (void)phpinfo:(id)sender
{
    [self hideKeyboard];
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:@"http://localhost:%hu/phpinfo.php",
                   [IPServer sharedServer].port]];
    [_myWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)benchmark:(id)sender
{
    NSString *destDir = [[[[NSFileManager defaultManager]
                           URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
                          lastObject] path];
    IPBenchmark *benchmark = [[IPBenchmark alloc] initWithDestinationDirectory:destDir];
    [self evaluateCode:[benchmark benchmarkCodeWithRepeat:25]];
}


- (void)evaluateCode:(NSString *)code
{
    if ([code characterAtIndex:code.length - 1] != ';') {
        code = [code stringByAppendingString:@";"];
    }
    [_phpEngine enqueueCode:code
                 completion:^(NSData *output){
                     const char *firstLine = [[NSString stringWithFormat:@"> %@\n\n", code] UTF8String];
                     NSMutableData *data = [NSMutableData dataWithBytes:firstLine length:strlen(firstLine)];
                     [data appendData:output];
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self setUTF8TEXT:data];
                     });
                 }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self eval:nil];
    return YES;
}

@end
