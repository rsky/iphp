//
//  IPEngine+Noamalize.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/12/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine+String.h"
#import "IPEngine+Extension.h"

@implementation IPEngine (String)

+ (int)startupStringExtension:(int)type moduleNumber:(int)module_number
{
    TSRMLS_FETCH();
    int flags = CONST_CS | ((type == MODULE_PERSISTENT) ? CONST_PERSISTENT : 0);

    // Unicode Normalization Forms (short)
    REGISTER_NS_LONG_CONSTANT("iPHP", "NFC",  NormalizationFormC, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NFD",  NormalizationFormD, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NFKC", NormalizationFormKC, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NFKD", NormalizationFormKD, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "HFS",  NormalizationFileSystem, flags);

    // Unicode Normalization Forms (long)
    REGISTER_NS_LONG_CONSTANT("iPHP", "NORMALIZATION_FORM_C",     NormalizationFormC, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NORMALIZATION_FORM_D",     NormalizationFormD, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NORMALIZATION_FORM_KC",    NormalizationFormKC, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NORMALIZATION_FORM_KD",    NormalizationFormKD, flags);
    REGISTER_NS_LONG_CONSTANT("iPHP", "NORMALIZATION_FILESYSTEM", NormalizationFileSystem, flags);

    return SUCCESS;
}

+ (NSString *)normalizeString:(NSString *)string withForm:(NSInteger)form
{
    switch (form) {
        case NormalizationFormC:
            return [string precomposedStringWithCanonicalMapping];
        case NormalizationFormD:
            return [string decomposedStringWithCanonicalMapping];
        case NormalizationFormKC:
            return [string precomposedStringWithCompatibilityMapping];
        case NormalizationFormKD:
            return [string decomposedStringWithCompatibilityMapping];
        case NormalizationFileSystem:
            return [NSString stringWithUTF8String:[string fileSystemRepresentation]];
    }
    return nil;
}

+ (zval *)normalizePHPString:(zval *)string
                    withForm:(NSInteger)form
               usingEncoding:(NSStringEncoding)encoding
        allowLossyConversion:(BOOL)lossy
{
    TSRMLS_FETCH();

    if (Z_TYPE_P(string) != IS_STRING) {
        return NULL;
    }

    @try {
        NSString *str = [[NSString alloc] initWithBytesNoCopy:Z_STRVAL_P(string)
                                                       length:Z_STRLEN_P(string)
                                                     encoding:encoding
                                                 freeWhenDone:NO];
        if (!str) {
            return NULL;
        }

        NSString *normalized = [self normalizeString:str withForm:form];
        if (!normalized) {
            return NULL;
        }

        NSData *data = [normalized dataUsingEncoding:encoding allowLossyConversion:lossy];
        if (data) {
            zval *result;
            MAKE_STD_ZVAL(result);
            ZVAL_STRINGL(result, data.bytes, data.length, 1);
            return result;
        }
    }
    @catch (id exception) {
        iphp_throw_exception(exception);
    }

    return NULL;
}

@end

#pragma mark - PHP functions

static void iphp_normalize_string_impl(INTERNAL_FUNCTION_PARAMETERS)
{
    char *string = NULL;
    int stringLength = 0;
    long form = NormalizationFormC;
    char *charset = NULL;
    int charsetLength = 0;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    zend_bool lossy = 1;

    if (zend_parse_parameters(ZEND_NUM_ARGS(), "s|lsb",
                              &string, &stringLength, &form,
                              &charset, &charsetLength, &lossy) == FAILURE) {
        return;
    }

    // detect encoding from IANA character set name
    if (charset) {
        NSString *charsetName = [[NSString alloc] initWithBytesNoCopy:charset
                                                               length:charsetLength
                                                             encoding:NSASCIIStringEncoding
                                                         freeWhenDone:NO];
        if (!charsetName) {
            php_error_docref(NULL TSRMLS_CC, E_WARNING, "Invalid character set name was given");
            RETURN_FALSE;
        }

        CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)charsetName);
        if (cfEncoding == kCFStringEncodingInvalidId) {
            php_error_docref(NULL TSRMLS_CC, E_WARNING, "Invalid character set name was given");
            RETURN_FALSE;
        }

        encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    }

    // create the source string
    NSString *source = [[NSString alloc] initWithBytesNoCopy:string
                                                      length:stringLength
                                                    encoding:encoding
                                                freeWhenDone:NO];
    if (!source) {
        php_error_docref(NULL TSRMLS_CC, E_WARNING, "Cannot load the given string");
        RETURN_FALSE;
    }

    // normalize
    if (form == NormalizationFormC || form == NormalizationFormKC ||
        form == NormalizationFormD || form == NormalizationFormKD) {
        NSString *normalized = [IPEngine normalizeString:source withForm:form];
        if (normalized) {
            NSData *data = [normalized dataUsingEncoding:encoding allowLossyConversion:lossy];
            if (data) {
                RETURN_STRINGL(data.bytes, data.length, 1);
            }
        }
        RETURN_FALSE;
    } else if (form == NormalizationFileSystem) {
        const char *fsrepr = [source fileSystemRepresentation];
        RETURN_STRING(fsrepr, 1);
    } else {
        php_error_docref(NULL TSRMLS_CC, E_WARNING, "Unknown normalization form was given");
        RETURN_FALSE;
    }
}

void iphp_normalize_string(INTERNAL_FUNCTION_PARAMETERS)
{
    @try {
        iphp_normalize_string_impl(INTERNAL_FUNCTION_PARAM_PASSTHRU);
    }
    @catch (id exception) {
        iphp_throw_exception(exception);
    }
}
