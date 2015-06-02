////
//  PersonViewController.m
//  iBook
//
//  Created by Lukasz Margielewski on 10-09-06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MIJSONRequestSecureSession.h"
#import "KeychainItemWrapper.h"

@interface MIJSONRequestSecureSession (Private)
@property (nonatomic, strong) KeychainItemWrapper *keychainSession;
@end

@implementation MIJSONRequestSecureSession{

 
    KeychainItemWrapper *_keychainSession;
    
}
@synthesize sessionDictionary = _sessionDictionary;
@synthesize identifier = _identifier;

#pragma mark - User & login session:

-(KeychainItemWrapper *)keychainSession{

    if (!_keychainSession) {
        
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *bundleIdentifier = [infoDictionary[@"CFBundleIdentifier"] stringByAppendingString:_identifier];
        _keychainSession = [[KeychainItemWrapper alloc] initWithIdentifier:bundleIdentifier accessGroup:nil];
    }
    
    return _keychainSession;
}

+(instancetype)sessionWithIdentifier:(NSString *)identifier{

    return [[MIJSONRequestSecureSession alloc] initWithIdentifier:identifier];
}

-(instancetype)initWithIdentifier:(NSString *)identifier{

    NSAssert(identifier != nil && identifier.length > 0, @"MIJSONRequestSecureSession must have identifier");
    
    return [[MIJSONRequestSecureSession alloc] initWithIdentifier:identifier];
}
-(void)storeSession:(NSDictionary *)sessionDictionary accountName:(NSString *)accountName{

    _sessionDictionary = sessionDictionary;
    
    if (accountName) {
    
        [self.keychainSession setObject:accountName forKey:(__bridge id)(kSecAttrAccount)];
    }
    
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:_sessionDictionary options:0 error:&error];
    
    if (data) {
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (jsonString) {
    
            [self.keychainSession setObject:jsonString forKey:(__bridge id)(kSecValueData)];
        }
    }
    

    
}
-(void)destroySession{

    _sessionDictionary = nil;
    [self.keychainSession resetKeychainItem];
}
-(NSDictionary *)tryToRecreateSession{

   NSString *jsonString = [self.keychainSession objectForKey:(__bridge id)(kSecValueData)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    return dict;
}

-(NSString *)autologinKey{

    return [NSString stringWithFormat:@"autologin_disabled_%@",  _identifier];
}
-(void)setAutoLoginEnabled:(BOOL)autologinEnabled{

    [[NSUserDefaults standardUserDefaults] setBool:!autologinEnabled forKey:[self autologinKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(BOOL)isAutoLoginEnabled{

    return ![[NSUserDefaults standardUserDefaults] boolForKey:[self autologinKey]];
}

-(NSDictionary *)sessionDictionary{
    
    if (!_sessionDictionary) {
        
        BOOL autologin = [self isAutoLoginEnabled];
        if (autologin) {
        
            _sessionDictionary = [self tryToRecreateSession];
        }
        
    }
    
    return _sessionDictionary;
}


@end
