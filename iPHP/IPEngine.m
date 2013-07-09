//
//  IPEngine.m
//  iPHP
//
//  Created by Ryusuke SEKIYAMA on 5/9/13.
//  Copyright (c) 2013 Ryusuke SEKIYAMA. All rights reserved.
//

#import "IPEngine.h"
#import "IPEngine+Extension.h"
#import "NSFileManager+IPUtility.h"
#import "ext/standard/html.h"

static IPEngine *sharedEngine = nil;

#ifdef ZTS
static PTSRMLS_D = NULL;
#endif

@interface IPEngine ()

@property (nonatomic, strong) NSMutableData *mutableBuffer;

@end

#pragma mark -

static void ip_flush(void *server_context)
{
    [sharedEngine flushBuffer];
}

static void ip_log_message(char *str TSRMLS_DC)
{
    NSLog(@"%s", str);
}

static int ip_ub_write(const char *str, unsigned int len TSRMLS_DC)
{
    [sharedEngine.mutableBuffer appendBytes:str length:len];
    return len;
}

const char *iphp_error_type_to_string(int type)
{
    switch (type) {
        case E_ERROR:
        case E_CORE_ERROR:
        case E_COMPILE_ERROR:
        case E_USER_ERROR:
            return "Fatal error";
            break;
        case E_RECOVERABLE_ERROR:
            return "Catchable fatal error";
            break;
        case E_WARNING:
        case E_CORE_WARNING:
        case E_COMPILE_WARNING:
        case E_USER_WARNING:
            return "Warning";
            break;
        case E_PARSE:
            return "Parse error";
            break;
        case E_NOTICE:
        case E_USER_NOTICE:
            return "Notice";
            break;
        case E_STRICT:
            return "Strict Standards";
            break;
        case E_DEPRECATED:
        case E_USER_DEPRECATED:
            return "Deprecated";
            break;
        default:
            return "Unknown error";
            break;
    }
}

#pragma mark -

@implementation IPEngine {
    dispatch_queue_t _queue;
    NSString *_queueIdentifier;
    NSString *_iniPath;
}

+ (IPEngine *)sharedEngine
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [self new];
    });
    return sharedEngine;
}

- (id)init
{
    return [self initWithPhpIni:[[NSBundle mainBundle]
                                 pathForResource:@"php"
                                 ofType:@"ini"
                                 inDirectory:@"etc"]];
}

- (id)initWithPhpIni:(NSString *)phpIni
{
    self = [super init];
    if (self) {
        _mutableBuffer = [NSMutableData new];
        _queueIdentifier = [NSString stringWithFormat:@"%@.%@",
                            [[NSBundle mainBundle] bundleIdentifier],
                            [[self class] description]];
        _queue = dispatch_queue_create([_queueIdentifier UTF8String], NULL);
        _iniPath = phpIni;
        [self startup];
        [self activate];
    }
    return self;
}

- (void)dealloc
{
    [self deactivate];
    [self shutdown];
}

#pragma mark - public methods

- (void)restart
{
    [self deactivate];
    [self shutdown];
    [self startup];
    [self activate];
}

- (void)gc
{
    gc_collect_cycles(TSRMLS_C);
}

- (NSData *)getBuffer
{
    return [NSData dataWithBytesNoCopy:_mutableBuffer.mutableBytes
                                length:_mutableBuffer.length
                          freeWhenDone:NO];
}

- (void)clearBuffer
{
    [_mutableBuffer setLength:0];
}

- (void)flushBuffer
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    if (_onFlushBuffer) {
        _onFlushBuffer(self);
    }
}

- (void)enqueueCode:(NSString *)code completion:(void (^)(NSData *))completion
{
    dispatch_async(_queue, ^{
        TSRMLS_FETCH();
        int shouldRestart = NO;

        PG(during_request_startup) = 0;

        zend_first_try {
            zend_eval_string((char *)[code UTF8String], NULL, "-" TSRMLS_CC);
        } zend_catch {
            NSLog(@"PHP %s:  %s in %s on line %d",
                  iphp_error_type_to_string(PG(last_error_type)),
                  PG(last_error_message),
                  PG(last_error_file),
                  PG(last_error_lineno));
            NSLog(@"exit_status = %d", EG(exit_status));
            shouldRestart = YES;
        } zend_end_try();

        if (completion) {
            completion([self getBuffer]);
        }

        [self clearBuffer];
        if (shouldRestart) {
            [self restart];
        }
    });
}

- (void)enqueueFilePath:(NSString *)filePath completion:(void (^)(NSData *))completion
{
    dispatch_async(_queue, ^{
        TSRMLS_FETCH();
        int shouldRestart = NO;
        zend_file_handle file_handle;

        file_handle.type = ZEND_HANDLE_FILENAME;
        file_handle.filename = [filePath fileSystemRepresentation];
        file_handle.handle.fp = NULL;
        file_handle.opened_path = NULL;
        file_handle.free_filename = 0;

        PG(during_request_startup) = 0;

        zend_first_try {
            if (zend_stream_open(file_handle.filename, &file_handle TSRMLS_CC) == FAILURE) {
                if (errno == EACCES) {
                    [_mutableBuffer appendBytes:"Access denied.\n"
                                         length:strlen("Access denied.\n")];
                } else {
                    [_mutableBuffer appendBytes:"No input file specified.\n"
                                         length:strlen("No input file specified.\n")];
                }
            } else {
                php_execute_script(&file_handle TSRMLS_CC);
            }
        } zend_catch {
            NSLog(@"PHP %s:  %s in %s on line %d",
                  iphp_error_type_to_string(PG(last_error_type)),
                  PG(last_error_message),
                  PG(last_error_file),
                  PG(last_error_lineno));
            NSLog(@"exit_status = %d", EG(exit_status));
            shouldRestart = YES;
        } zend_end_try();
        
        if (completion) {
            completion([self getBuffer]);
        }
        
        [self clearBuffer];
        if (shouldRestart) {
            [self restart];
        }
    });
}

#pragma mark - ZEND API wrappers

- (int)startup
{
    TSRMLS_FETCH();
    int argc = 1;
    char *argv[1] = {"php"};

    php_embed_module.flush = ip_flush;
    php_embed_module.log_message = ip_log_message;
    php_embed_module.ub_write = ip_ub_write;
    if (_iniPath) {
        php_embed_module.php_ini_path_override = (char *)_iniPath.fileSystemRepresentation;
    }
    php_embed_init(argc, argv PTSRMLS_CC);

    if ([self registerModule:[IPEngine getModuleEntry]] == FAILURE) {
        return FAILURE;
    }

    return SUCCESS;
}

- (void)shutdown
{
    TSRMLS_FETCH();
    php_embed_shutdown(TSRMLS_C);
}

- (int)activate
{
    TSRMLS_FETCH();

    // get path for user directories
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentDirectory = [fileManager userDomainPathForDirectory:NSDocumentDirectory];
    NSString *cachesDirectory = [fileManager userDomainPathForDirectory:NSCachesDirectory];

    // set path for the error log file
    NSString *logFilePath = [[[cachesDirectory
                               stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier]
                              stringByAppendingPathComponent:@"php_error"]
                             stringByAppendingPathExtension:@"log"];
    // set error_log ini entry
    const char *errorLog = logFilePath.fileSystemRepresentation;
    if (zend_alter_ini_entry_ex("error_log", sizeof("error_log"),
                                (char *)errorLog, strlen(errorLog),
                                PHP_INI_SYSTEM, PHP_INI_STAGE_ACTIVATE, 0 TSRMLS_CC) == FAILURE) {
        NSLog(@"%s: Failed to set ini entry 'error_log' = '%@'", __FUNCTION__, logFilePath);
        return FAILURE;
    }

    // chdir ~/Documents
    if (VCWD_CHDIR(documentDirectory.fileSystemRepresentation) != 0) {
        NSLog(@"%s: Failed to chdir to '%@'", __FUNCTION__, documentDirectory);
        return FAILURE;
    }

    return SUCCESS;
}

- (int)deactivate
{
    TSRMLS_FETCH();
    return SUCCESS;
}

- (int)registerModule:(zend_module_entry *)module_entry
{
    TSRMLS_FETCH();

    module_entry->type = MODULE_PERSISTENT;
    module_entry->module_number = zend_next_free_module();
    module_entry->handle = NULL;

    if ((module_entry = zend_register_module_ex(module_entry TSRMLS_CC)) == NULL) {
        return FAILURE;
    }

    if (zend_startup_module_ex(module_entry TSRMLS_CC) == FAILURE) {
        return FAILURE;
    }

    if (module_entry->request_startup_func) {
        if (module_entry->request_startup_func(MODULE_PERSISTENT, module_entry->module_number TSRMLS_CC) == FAILURE) {
            NSLog(@"Unable to initialize module '%s'", module_entry->name);
            php_error_docref(NULL TSRMLS_CC, E_CORE_WARNING, "Unable to initialize module '%s'", module_entry->name);
            return FAILURE;
        }
    }

    return SUCCESS;
}

@end
