//
//  IPEngine+Image.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/12/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine.h"

@class CALayer;

@interface IPEngine (Image)

+ (int)startupImageExtension:(int)type moduleNumber:(int)module_number;
+ (NSData *)takeScreenshotWithErrorType:(int)type;
+ (NSData *)takeScreenShot;
+ (NSData *)captureView:(UIView *)view;
+ (NSData *)renderLayer:(CALayer *)layer size:(CGSize)size;

@end

#pragma mark - PHP function prototypes

PHP_NAMED_FUNCTION(iphp_get_screenshot);
PHP_NAMED_FUNCTION(iphp_save_image_data_to_cameraroll);
PHP_NAMED_FUNCTION(iphp_imagick_write_image_to_cameraroll);
PHP_NAMED_FUNCTION(iphp_gd_image_grab_screen);
