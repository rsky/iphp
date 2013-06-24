//
//  IPEngine+Image.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/12/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine+Image.h"
#import "IPEngine+Extension.h"
#import <QuartzCore/QuartzCore.h>

#include "ext/imagick/php_imagick_shared.h"
#include "ext/gd/php_gd.h"
#include "ext/gd/libgd/gd.h"

static zend_class_entry *imagick_ce;

typedef struct {
    const char *bytes;
    int length;
    int consumed;
} memoryDataSourceCtx;

#pragma mark utility functions

static void copy_ctor_for_imagick(zend_function *function)
{
    function->common.scope = imagick_ce;
    function_add_ref(function);
    //NSLog(@"[%d,0x%x] %s::%s", function->common.type, function->common.fn_flags, function->common.scope->name, function->common.function_name);
}

static zend_bool merge_check_function_existence(HashTable *target_ht, void *source_data, zend_hash_key *hash_key, zend_class_entry *target_ce)
{
    if (zend_hash_quick_exists(&target_ce->function_table, hash_key->arKey, hash_key->nKeyLength, hash_key->h)) {
        //NSLog(@"0:%s", hash_key->arKey);
        return 0;
    } else {
        //NSLog(@"1:%s", hash_key->arKey);
        return 1;
    }
}

static int memory_data_source(void *context, char *buffer, int len)
{
    memoryDataSourceCtx *ctx = context;

    int read_length = MIN(len, ctx->length - ctx->consumed);
    if (read_length > 0) {
        memcpy(buffer, ctx->bytes + ctx->consumed, read_length);
        ctx->consumed += read_length;
    } else if (read_length < 0) {
        read_length = 0;
    }

    return read_length;
}

#pragma mark -

@implementation IPEngine (Image)

+ (int)startupImageExtension:(int)type moduleNumber:(int)module_number
{
    TSRMLS_FETCH();
    imagick_ce = php_imagick_get_class_entry();

    HashTable function_table;
    zend_hash_init_ex(&function_table, 0, NULL, ZEND_FUNCTION_DTOR, 1, 0);
    zend_function_entry imagick_addtional_functions[] = {
        ZEND_NAMED_ME(writeImageToCameraRoll, iphp_imagick_write_image_to_cameraroll, NULL, ZEND_ACC_PUBLIC)
        PHP_FE_END
    };

    int ret = zend_register_functions(NULL, imagick_addtional_functions,
                                      &function_table, type TSRMLS_CC);
    if (ret == SUCCESS) {
        zend_hash_merge_ex(&imagick_ce->function_table, &function_table,
                           (copy_ctor_func_t) copy_ctor_for_imagick, sizeof(zend_function),
                           (merge_checker_func_t) merge_check_function_existence, imagick_ce);
    }
    zend_hash_destroy(&function_table);

    return ret;
}

+ (NSData *)takeScreenshotWithErrorType:(int)type
{
    NSData *data = nil;
    @try {
        data = [self takeScreenShot];
    }
    @catch (id exception) {
        TSRMLS_FETCH();
        if (type == IPHP_E_EXCEPTION) {
            iphp_throw_exception(exception);
        } else {
            php_error_docref(NULL TSRMLS_CC, type, "%s", [[exception description] UTF8String]);
        }
    }
    return data;
}

+ (NSData *)takeScreenShot
{
    return [self captureView:[UIApplication sharedApplication].keyWindow];
}

+ (NSData *)captureView:(UIView *)view
{
    return [self renderLayer:view.layer size:view.frame.size];
}

+ (NSData *)renderLayer:(CALayer *)layer size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextFillRect(ctx, CGRectMake(0.0, 0.0, size.width, size.height));
    [layer renderInContext:ctx];
    NSData *data =  UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext());
    UIGraphicsEndImageContext();
    return data;
}

+ (BOOL)saveImageDataToCameraRoll:(NSData *)data
{
    UIImage *image = [[UIImage alloc] initWithData:data];
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
        return YES;
    } else {
        return NO;
    }
}

@end

#pragma mark - PHP functions

void iphp_get_screenshot(INTERNAL_FUNCTION_PARAMETERS)
{
    if (zend_parse_parameters_none() == FAILURE) {
        return;
    }

    NSData *screenshot = [IPEngine takeScreenshotWithErrorType:E_WARNING];
    if (screenshot) {
        RETVAL_STRINGL(screenshot.bytes, screenshot.length, 1);
    } else {
        RETVAL_FALSE;
    }
}

void iphp_save_image_data_to_cameraroll(INTERNAL_FUNCTION_PARAMETERS)
{
    char *bytes = NULL;
    int length = 0;

    if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &bytes, &length) == FAILURE) {
        return;
    }

    @try {
        NSData *data = [[NSData alloc] initWithBytes:bytes length:(NSUInteger)length];
        RETVAL_BOOL([IPEngine saveImageDataToCameraRoll:data]);
    }
    @catch (id exception) {
        iphp_throw_exception(exception);
    }
}

void iphp_imagick_write_image_to_cameraroll(INTERNAL_FUNCTION_PARAMETERS)
{
    if (zend_parse_parameters_none() == FAILURE) {
        return;
    }

    php_imagick_object *intern = (php_imagick_object *)zend_object_store_get_object(this_ptr TSRMLS_CC);
    size_t length = 0;
    unsigned char *bytes = MagickGetImageBlob(intern->magick_wand, &length);

    if (bytes) {
        @try {
            NSData *data = [[NSData alloc] initWithBytes:bytes length:(NSUInteger)length];
            RETVAL_BOOL([IPEngine saveImageDataToCameraRoll:data]);
        }
        @catch (id exception) {
            iphp_throw_exception_ex(php_imagick_exception_class_entry, 0, exception);
        }
        @finally {
            MagickRelinquishMemory(bytes);
        }
    } else {
        ExceptionType severity = UndefinedException;
        char *description = MagickGetException(intern->magick_wand, &severity);
        if (strlen(description) == 0) {
            zend_throw_exception(php_imagick_exception_class_entry, "Unknown Error", 1 TSRMLS_CC);
        } else {
            zend_throw_exception(php_imagick_exception_class_entry, description, severity TSRMLS_CC);
            MagickRelinquishMemory(description);
            MagickClearException(intern->magick_wand);
        }
    }
}

void iphp_gd_image_grab_screen(INTERNAL_FUNCTION_PARAMETERS)
{
    if (zend_parse_parameters_none() == FAILURE) {
        return;
    }

    NSData *screenshot = [IPEngine takeScreenshotWithErrorType:E_WARNING];
    if (!screenshot) {
        RETURN_FALSE;
    }

    memoryDataSourceCtx ctx = {
        .bytes = [screenshot bytes],
        .length = [screenshot length],
        .consumed = 0
    };
    gdSource source = {
        .source = memory_data_source,
        .context = &ctx
    };
    gdImagePtr im = gdImageCreateFromPngSource(&source);
    if (im) {
        ZEND_REGISTER_RESOURCE(return_value, im, phpi_get_le_gd());
    } else {
        RETVAL_FALSE;
    }
}
