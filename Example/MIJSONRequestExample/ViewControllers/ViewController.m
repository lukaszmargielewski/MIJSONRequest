//
//  ViewController.m
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 29/05/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "ViewController.h"
#import "MIJSONRequestManager.h"
#import "ChildtestViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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
    }
}

@end
