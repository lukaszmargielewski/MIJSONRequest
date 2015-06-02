//
//  PersonViewController.h
//  iBook
//
//  Created by Lukasz Margielewski on 10-09-06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface MIJSONRequestSecureSession : NSObject{

}

#pragma mark - User fields:
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSDictionary *sessionDictionary;

+(instancetype)sessionWithIdentifier:(NSString *)identifier;
-(instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

-(BOOL)isValid;

-(void)storeSession:(NSDictionary *)sessionDictionary accountName:(NSString *)accountName;
-(void)destroySession;

-(void)setAutoLoginEnabled:(BOOL)autologinEnabled;
-(BOOL)isAutoLoginEnabled;

@end