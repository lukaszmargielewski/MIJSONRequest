//
//  ViewController.m
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 29/05/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "ViewController.h"
#import "MIJSONRequestManager.h"
#import "MIJSONRequestAuthenticateExample.h"

#import "ChildtestViewController.h"

@interface ViewController ()
@property (nonatomic, strong) MIJSONRequestManager *requestManager;
@property (nonatomic, strong) MIJSONRequestAuthenticateExample *exampleAuthenticate;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}
-(MIJSONRequestManager *)requestManager{

    if (!_requestManager) {
        _requestManager = [MIJSONRequestManager requestManagerWithUrlString:@"https://webservice.mobile-identity.com/plugins/mflife/json" hostName:@"htp://www.mobilefitness.dk"];
        _requestManager.httpMethodDefault = @"POST";
        _exampleAuthenticate = [[MIJSONRequestAuthenticateExample alloc] init];
        _requestManager.authDelegate = _exampleAuthenticate;
    }
    
    return _requestManager;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    ChildtestViewController *cvc = [segue destinationViewController];
    if ([cvc isKindOfClass:[ChildtestViewController class]]) {
        cvc.requestManager = self.requestManager;
    }
}

@end
