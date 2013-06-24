//
//  IPEngine+Extension.h
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/12/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine.h"
#include "ext/spl/spl_exceptions.h"
#include "zend_exceptions.h"

#define IPHP_MODULE_VERSION "0.0.1"

#define IPHP_E_EXCEPTION INT_MAX

ZEND_BEGIN_MODULE_GLOBALS(iphp)
char *documentationDir;
char *libraryDir;
char *cachesDir;
char *tmpDir;
ZEND_END_MODULE_GLOBALS(iphp)

ZEND_EXTERN_MODULE_GLOBALS(iphp);

#ifdef ZTS
#define IPHPG(v) TSRMG(iphp_globals_id, zend_iphp_globals *, v)
#else
#define IPHPG(v) (iphp_globals.v)
#endif

@interface IPEngine (Extension)

+ (zend_module_entry *)getModuleEntry;

@end

PHP_NAMED_FUNCTION(iphp_log);

static zend_always_inline void iphp_throw_exception_ex(zend_class_entry *exception_ce, long code, id exception TSRMLS_DC)
{
    zend_throw_exception_ex(exception_ce, code TSRMLS_CC, "%s", [[exception description] UTF8String]);
}

static zend_always_inline void _iphp_throw_exception(id exception TSRMLS_DC)
{
    iphp_throw_exception_ex(spl_ce_RuntimeException, 0 TSRMLS_CC, exception);
}

#define iphp_throw_exception(exception) _iphp_throw_exception(exception TSRMLS_CC)
