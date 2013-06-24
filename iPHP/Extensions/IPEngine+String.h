//
//  IPEngine+Noamalize.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/12/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine.h"

enum {
    NormalizationFormC,
    NormalizationFormD,
    NormalizationFormKC,
    NormalizationFormKD,
    NormalizationFileSystem
};

@interface IPEngine (String)

+ (int)startupStringExtension:(int)type moduleNumber:(int)module_number;
+ (NSString *)normalizeString:(NSString *)string withForm:(NSInteger)form;
+ (zval *)normalizePHPString:(zval *)string
                    withForm:(NSInteger)form
               usingEncoding:(NSStringEncoding)encoding
        allowLossyConversion:(BOOL)lossy;

@end

PHP_NAMED_FUNCTION(iphp_normalize_string);
