//
//  ChildtestViewController.m
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 01/06/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "ChildtestViewController.h"
#import "MIJSONRequestManager.h"
#import "MIJSONApi.h"

@interface ChildtestViewController ()

@end

@implementation ChildtestViewController{

    MIJSONRequest *request;
}

- (void)dealloc{

    [[MIJSONApi requestManager]  cancelRequest:request];
}
///*
-(void)viewWillDisappear:(BOOL)animated{

    [[MIJSONApi requestManager] cancelAllRequestsForClient:self];
    [[MIJSONApi requestManager] cancelRequest:request];
}
// */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)startTestRequestAndPop:(id)sender {
    
    
    [self testRequestWithPop:YES];
    
}

- (IBAction)startTestRequestWithoutPup:(id)sender {
    [self testRequestWithPop:NO];
}

- (void)testRequestWithPop:(BOOL)pop{

    __block ChildtestViewController *blockSelf = self;
    
    request = [[MIJSONApi requestManager] startRequestWithJSONDictionary:
                @{
                  @"action" : @"validate",
                  @"signup_code" : @"mf2100"
                  } completionBlock:^(MIJSONRequest *action, NSDictionary *response, NSError *error){
        
        NSLog(@"finished: with response: %@  Error: %@", response, error);
        [blockSelf testDummyCompeteMethod:response];
        
    }];
    
    if (pop) {
    
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}
-(void)testDummyCompeteMethod:(NSDictionary *)response{

    NSLog(@"testDummyCompeteMethod....");
}
@end
