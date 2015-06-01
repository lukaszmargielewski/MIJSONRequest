//
//  ChildtestViewController.h
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 01/06/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MIJSONRequestManager;

@interface ChildtestViewController : UIViewController
- (IBAction)startTestRequestAndPop:(id)sender;
- (IBAction)startTestRequestWithoutPup:(id)sender;

@property (nonatomic, assign) MIJSONRequestManager *requestManager;

@end
