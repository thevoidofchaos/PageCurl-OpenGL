//
//  PageCurlView.h
//  OpenGL
//
//  Created by Mahoone on 2020/8/3.
//  Copyright © 2020 Mahoone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PageCurlView;

@protocol PageCurlViewProtocol <NSObject>
@optional

- (void)pageCurlViewBeginDragging:(PageCurlView * _Nonnull )pageCurlView;

- (void)pageCurlViewDidDragging:(PageCurlView * _Nonnull )pageCurlView direction:(CGPoint)direction;

- (void)pageCurlViewEndDragging:(PageCurlView * _Nonnull )pageCurlView success:(BOOL)success;

@end


NS_ASSUME_NONNULL_BEGIN

@interface PageCurlView : UIView

@property (nonatomic, weak, nullable) id <PageCurlViewProtocol> delegate;

@property(nonatomic,assign)CGFloat radius;

-(instancetype)initWithFrontImage:(UIImage*)front backImage:(UIImage*)back frame:(CGRect)frame;

-(void)curlToDirection:(CGPoint)direction;

-(void)reset;

@end

NS_ASSUME_NONNULL_END
