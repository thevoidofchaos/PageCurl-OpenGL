//
//  ViewController.m
//  OpenGL
//
//  Created by Mahoone on 2020/8/3.
//  Copyright © 2020 Mahoone. All rights reserved.
//

#import "ViewController.h"
#import "PageCurlView.h"
@interface ViewController ()<PageCurlViewProtocol>
{
    PageCurlView *page;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIImage *back = [UIImage imageNamed:@"Rectangle 2.png"];
    UIImage *front = [UIImage imageNamed:@"Rectangle 1.png"];

    page = [PageCurlView.alloc initWithFrontImage:front backImage:back frame:CGRectMake(0, UIScreen.mainScreen.bounds.size.height - 200, UIScreen.mainScreen.bounds.size.width, 200)];
    [self.view addSubview:page];
    
    
}

//Reset
-(void)btnClick{
    [page reset];
}

#pragma mark - delegate
-(void)pageCurlViewEndDragging:(PageCurlView *)pageCurlView success:(BOOL)success{
    NSLog(@"===========EndDragging===success:%d",success);
}

-(void)pageCurlViewDidDragging:(PageCurlView *)pageCurlView direction:(CGPoint)direction{
    NSLog(@"====DidDragging===directon:%@",NSStringFromCGPoint(direction));
}

-(void)pageCurlViewBeginDragging:(PageCurlView *)pageCurlView{
    NSLog(@"=========BeginDragging");
}

@end
