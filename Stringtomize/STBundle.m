//
//  Bundle+Stringtomize.m
//  Stringtomize
//
//  Created by Matteo Gavagnin on 20/07/15.
//  Copyright (c) 2015 DIMENSION. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "STBundle.h"
#import "StringtomizeManager.h"

static const NSString* lang;
static const char _bundle=0;

static const NSString* baseLanguage;

@implementation STBundle


-(NSString*)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle* bundle = objc_getAssociatedObject(self, &_bundle);
    
    NSString *retVal = bundle ? [bundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
    
    // NSString *retVal = [super localizedStringForKey:key value:value table:tableName];
    
    [[StringtomizeManager sharedInstance] stringtomizeKey:key value:value table:tableName];
    
    return retVal;
}

+(void)setLanguage:(NSString*)language {
    [STBundle baseLanguage];
    
    if (language!= nil) {
        lang = language;
    } else {
        lang = baseLanguage;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      object_setClass([NSBundle mainBundle],[STBundle class]);
                  });
    ;
    objc_setAssociatedObject([NSBundle mainBundle], &_bundle, language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+(NSString *)currentLanguage {
    return  (NSString *)lang;
}

+(NSString *)baseLanguage {
    if (baseLanguage == nil) {
        baseLanguage = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDevelopmentRegion"];
    }
    return  (NSString *)baseLanguage;
}

+ (NSArray *)supportedLanguages {
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.lproj'"];
    NSArray *onlyLproj = [dirContents filteredArrayUsingPredicate:fltr];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSString * path in onlyLproj) {
        if ([path isEqualToString:@"Base.lproj"]) {
            // TODO: don't add anything if there is also the string file for the storyboard?
            // [result addObject:nativeLanguage];
        } else {
            [result addObject:[path.lastPathComponent stringByDeletingPathExtension]];
        }
    }
    return result;
}


@end