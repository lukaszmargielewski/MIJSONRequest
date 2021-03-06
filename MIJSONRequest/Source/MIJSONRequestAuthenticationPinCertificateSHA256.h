//
//  MIJSONRequestAuthenticateSimple.h
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 01/06/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIJSONRequestAuthenticate.h"


@interface MIJSONRequestAuthenticationPinCertificateSHA256 : NSObject<MIJSONRequestAuthenticationDelegate>

@property (nonatomic, copy) NSString *certificateSha;

@end
