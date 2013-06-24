//
//  IPEngine+Extension.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/12/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine+Extension.h"
#import "IPEngine+Image.h"
#import "IPEngine+String.h"
#import "NSFileManager+IPUtility.h"
#include "ext/standard/info.h"

ZEND_DECLARE_MODULE_GLOBALS(iphp);

#pragma mark module functions

static PHP_MINIT_FUNCTION(iphp)
{
    NSLog(@"%s", __FUNCTION__);
    int flags = CONST_CS | ((type == MODULE_PERSISTENT) ? CONST_PERSISTENT : 0);

    REGISTER_NS_STRING_CONSTANT("iPHP", "DOCUMENTATION_DIR", IPHPG(documentationDir), flags);
    REGISTER_NS_STRING_CONSTANT("iPHP", "LIBRARY_DIR", IPHPG(libraryDir), flags);
    REGISTER_NS_STRING_CONSTANT("iPHP", "CACHES_DIR", IPHPG(cachesDir), flags);
    REGISTER_NS_STRING_CONSTANT("iPHP", "TMP_DIR", IPHPG(tmpDir), flags);

    @autoreleasepool {
        if ([IPEngine startupImageExtension:type moduleNumber:module_number] == FAILURE) {
            return FAILURE;
        }
        if ([IPEngine startupStringExtension:type moduleNumber:module_number] == FAILURE) {
            return FAILURE;
        }
    }

    return SUCCESS;
}

static PHP_GINIT_FUNCTION(iphp)
{
    NSLog(@"%s", __FUNCTION__);
    @autoreleasepool {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path;

        path = [fileManager userDomainPathForDirectory:NSDocumentationDirectory];
        iphp_globals->documentationDir = pestrdup([path fileSystemRepresentation], 1);

        path = [fileManager userDomainPathForDirectory:NSLibraryDirectory];
        iphp_globals->libraryDir = pestrdup([path fileSystemRepresentation], 1);

        path = [fileManager userDomainPathForDirectory:NSCachesDirectory];
        iphp_globals->cachesDir = pestrdup([path fileSystemRepresentation], 1);

        path = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"_"]
                stringByDeletingLastPathComponent];
        iphp_globals->tmpDir = pestrdup([path fileSystemRepresentation], 1);
    }
}

static PHP_GSHUTDOWN_FUNCTION(iphp)
{
    NSLog(@"%s", __FUNCTION__);
    pefree(iphp_globals->documentationDir, 1);
    pefree(iphp_globals->libraryDir, 1);
    pefree(iphp_globals->cachesDir, 1);
    pefree(iphp_globals->tmpDir, 1);
}

static PHP_MINFO_FUNCTION(iphp)
{
    php_info_print_table_start();
    php_info_print_table_row(2, "iPHP support", "enabled");
    php_info_print_table_row(2, "iPHP version", IPHP_MODULE_VERSION);
    php_info_print_table_end();
}

#pragma mark argument informations

ZEND_BEGIN_ARG_INFO(arginfo_log, 0)
ZEND_ARG_INFO(0, message)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_normalize_string, 0, 0, 1)
ZEND_ARG_INFO(0, string)
ZEND_ARG_INFO(0, form)
ZEND_ARG_INFO(0, encoding)
ZEND_ARG_INFO(0, lossy)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO(arginfo_save_image_data_to_cameraroll, 0)
ZEND_ARG_INFO(0, image)
ZEND_END_ARG_INFO()

#pragma mark function entries

#define IPHP_RAW_NS_FE(name, zend_name, arg_info, flags) ZEND_RAW_FENTRY("iPHP\\" #name, zend_name, arg_info, (flags))

static zend_function_entry iphp_functions[] = {
    IPHP_RAW_NS_FE(log, iphp_log, arginfo_log, 0)
    IPHP_RAW_NS_FE(normalizeString, iphp_normalize_string, arginfo_normalize_string, 0)
    IPHP_RAW_NS_FE(getScreenShot, iphp_get_screenshot, NULL, 0)
    IPHP_RAW_NS_FE(saveImageDataToCameraRoll, iphp_save_image_data_to_cameraroll, arginfo_save_image_data_to_cameraroll, 0)
    PHP_RAW_NAMED_FE(imagegrabscreen, iphp_gd_image_grab_screen, NULL)
    PHP_FE_END
};

#pragma mark module entry

static zend_module_dep iphp_module_deps[] = {
    ZEND_MOD_REQUIRED("imagick")
    ZEND_MOD_REQUIRED("spl")
    ZEND_MOD_END
};

static zend_module_entry iphp_module_entry = {
    STANDARD_MODULE_HEADER_EX,
    NULL,
    iphp_module_deps,
    "iPHP",
    iphp_functions,
    PHP_MINIT(iphp),
    NULL,
    NULL,
    NULL,
    PHP_MINFO(iphp),
    IPHP_MODULE_VERSION,
    PHP_MODULE_GLOBALS(iphp),
    PHP_GINIT(iphp),
    PHP_GSHUTDOWN(iphp),
    NULL,
    STANDARD_MODULE_PROPERTIES_EX
};

#pragma mark -

@implementation IPEngine (Extension)

+ (zend_module_entry *)getModuleEntry
{
    return &iphp_module_entry;
}

@end

#pragma mark - PHP functions

void iphp_log(INTERNAL_FUNCTION_PARAMETERS)
{
    char *message = NULL;
    int length = 0;

    if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &message, &length) == FAILURE) {
        return;
    }

    NSLog(@"%s", message);
}
