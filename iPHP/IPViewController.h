//
//  IPViewController.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/9/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IPViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic) IBOutlet UITextField *myCode;
@property (nonatomic) IBOutlet UIWebView *myWebView;

- (IBAction)clear:(id)sender;
- (IBAction)eval:(id)sender;
- (IBAction)phpinfo:(id)sender;
- (IBAction)benchmark:(id)sender;

@end
