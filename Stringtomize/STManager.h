//
//  STManager.h
//  Stringtomize
//
//  Created by Matteo Gavagnin on 17/07/15.
//  Copyright (c) 2015 DIMENSION. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STManager : NSObject

+ (id)sharedInstance;
- (void)stringtomizeKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName;
- (void)uploadBaseLanguageStrings;
- (void)uploadTranslationStrings;
- (void)uploadTranslationStringsOverwriting:(BOOL)overwrite;

@property (nonatomic) NSString *endpoint;
@property (nonatomic) BOOL verbose;
@property (nonatomic) NSString *token;
@end