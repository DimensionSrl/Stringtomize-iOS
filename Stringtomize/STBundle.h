//
//  STBundle.h
//  Stringtomize
//
//  Created by Matteo Gavagnin on 20/07/15.
//  Copyright (c) 2015 DIMENSION. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STBundle : NSBundle

+(void)setLanguage:(NSString*)language;
+(NSString *)currentLanguage;
+(NSArray *)supportedLanguages;
+(NSString *)baseLanguage;
@end
