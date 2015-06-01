//
//  ChildtestViewController.m
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 01/06/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "ChildtestViewController.h"
#import "MIJSONRequestManager.h"
@interface ChildtestViewController ()

@end

@implementation ChildtestViewController

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
    
    
    __block ChildtestViewController *blockSelf = self;
    
    MIJSONRequest *request = [self.requestManager startRequestWithJSONDictionary:@{@"action" : @"validate", @"signup_code" : @"mf2100"} startBlock:^(MIJSONRequest *request, BOOL started){
    
        NSLog(@"started: %i", started);
        
    } progressBlock:^(MIJSONRequest *requet, float progress) {
    
        NSLog(@"progress: %f", progress);
        
    }completionBlock:^(MIJSONRequest *request, enum MIJSONRequestResult result, NSDictionary *respone, NSError *error){
    
        NSLog(@"finished: %lu, response: %@  Error: %@", (unsigned long)result, respone, error);
        [blockSelf testDummyCompeteMethod:respone];
        
    } client:self];
   
    [self.navigationController popViewControllerAnimated:NO];
    
}
-(void)testDummyCompeteMethod:(NSDictionary *)response{

    NSLog(@"testDummyCompeteMethod....");
}
@end
