//
//  MIJSONApi.h
//  Hillerod
//
//  Created by Lukasz Margielewski on 03/06/15.
//  Copyright (c) 2015 Mobile Fitness. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIJSONRequestManager.h"

extern NSString *kMIJSONApi_SessionKey;
extern NSString *kMIJSONApi_DeviceIdKey;

@interface MIJSONApi : NSObject

+(MIJSONRequestManager *)requestManager;

@end