//
//  STManager.m
//  Stringtomize
//
//  Created by Matteo Gavagnin on 17/07/15.
//  Copyright (c) 2015 DIMENSION. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STManager.h"
#import "STBundle.h"

static const NSString* bundleId;
static const NSString* version;
static const NSString* build;

NSString* stringtomizeAddress = @"example.com";

@implementation STManager {
    
}

+ (instancetype)sharedInstance {
    static STManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.endpoint = stringtomizeAddress;
        bundleId = [[NSBundle mainBundle] bundleIdentifier];
        version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        sharedInstance.verbose = false;
        sharedInstance.token = @"DEFAULT TOKEN";
    });
    
    return sharedInstance;
}

- (void)stringtomizeKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{@"Authorization": [NSString stringWithFormat:@"Token token=\"%@\"", self.token]};
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v1/apps/%@/phrases/%@", self.endpoint, bundleId, [STBundle baseLanguage]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
    NSString *table = @"";
    if (tableName) {
        table = tableName;
    }
    NSDictionary *phrase = [[NSDictionary alloc] initWithObjects:@[value, key, table, [STBundle baseLanguage], version, build, @1] forKeys:@[@"string", @"identifier", @"path", @"base", @"version", @"build", @"platform"]];
    NSDictionary *root = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:self.verbose], phrase] forKeys:@[@"verbose", @"phrase"]];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    [request setHTTPBody:postData];
    
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (self.verbose) {
            if ([tableName isEqualToString:@""]) {
                NSLog(@"Stringtomize: sent %@ = %@", key, value);
            } else {
                NSLog(@"Stringtomize: sent %@ = %@ (%@)", key, value, tableName);
            }
            
            // NSLog(@"%@", response);
            if (data) {
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!([string isEqualToString:@"{}"] || [string isEqualToString:@""])) {
                    NSLog(@"Stringtomize: %@", string);
                }
            }
        }
    }];
    
    [postDataTask resume];
}

- (void)uploadBaseLanguageStrings {
    [self uploadStringsForLanguage:[STBundle baseLanguage] overwrite:false];
}

- (void)uploadTranslationStrings {
    for (NSString *lang in [STBundle supportedLanguages]) {
        if (![lang isEqualToString:[STBundle baseLanguage]]) {
            [self uploadStringsForLanguage:lang overwrite:false];
        }
    }
}

- (void)uploadTranslationStringsOverwriting:(BOOL)overwrite {
    for (NSString *lang in [STBundle supportedLanguages]) {
        if (![lang isEqualToString:[STBundle baseLanguage]]) {
            [self uploadStringsForLanguage:lang overwrite:overwrite];
        }
    }
}

- (void)uploadStringsForLanguage:(NSString *)language overwrite:(BOOL)overwrite {
    if (language == nil) {
        NSLog(@"Stringtomize Manager: nil language provided");
        return;
    }
    
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSString *languageLproj = [bundleRoot stringByAppendingString:[NSString stringWithFormat:@"/%@.lproj", language]];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm subpathsOfDirectoryAtPath:languageLproj error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.strings'"];
    NSArray *onlyStrings = [dirContents filteredArrayUsingPredicate:fltr];
    
    BOOL translation = false;
    
    if (![language isEqualToString:[STBundle baseLanguage]]) {
        translation = true;
    }
    
    for (NSString *path in onlyStrings) {
        [self parseAndUploadStringsFile:[languageLproj stringByAppendingPathComponent:path] forLanguage:language asTranslations:translation overwrite:overwrite];
    }
}

- (void)parseAndUploadStringsFile:(NSString *)filePath forLanguage:(NSString *)language asTranslations:(BOOL)translations overwrite:(BOOL)overwrite {
    
    NSString *tableName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSDictionary *fileDictionary = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{@"Authorization": [NSString stringWithFormat:@"Token token=\"%@\"", self.token]};
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    NSURL *url;
    
    if (translations) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v1/apps/%@/translations/%@/batch", self.endpoint, bundleId, language]];
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v1/apps/%@/phrases/%@/batch", self.endpoint, bundleId, language]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];

    NSMutableArray *phrases = [[NSMutableArray alloc] init];
    [fileDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * value, BOOL *stop) {
        NSDictionary *phrase;
        if (translations) {
            phrase = [[NSDictionary alloc] initWithObjects:@[value, key, tableName, language, @1] forKeys:@[@"string", @"identifier", @"path", @"base", @"platform"]];
        } else {
            phrase = [[NSDictionary alloc] initWithObjects:@[value, key, tableName, language, @1, version, build] forKeys:@[@"string", @"identifier", @"path", @"base", @"platform", @"version", @"build"]];
        }
        [phrases addObject:phrase];
    }];
    
    if (phrases.count == 0) {
        return;
    }
    
    NSDictionary *root;
    if (translations) {
        root = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:self.verbose], phrases, [NSNumber numberWithBool:overwrite]] forKeys:@[@"verbose", @"translations", @"overwrite"]];
    } else {
        root = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:self.verbose], phrases] forKeys:@[@"verbose", @"phrases"]];
    }

    NSData *postData = [NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (self.verbose) {
            NSLog(@"Stringtomize: Uploaded %@/%@", language, tableName);
            // NSLog(@"%@", response);
            if (data) {
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!([string isEqualToString:@"{}"] || [string isEqualToString:@""])) {
                    NSLog(@"Stringtomize: %@", string);
                }
            }
        }
    }];
    
    [postDataTask resume];
}

@end