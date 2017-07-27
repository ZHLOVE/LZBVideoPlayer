//
//  LZBVideoPlayerView.h
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/27.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol LZBVideoPlayerLoadingDelegate <NSObject>

@required
- (void)startAnimating;
- (void)stopAnimating;

@end

@interface LZBVideoPlayerView : UIView

/**
 传入播放的路径，以及需要显示类的父类
 
 @param url 可以传入本地路径、也可以传入网络路径，自动播放
 @param isSupportCache 是否支持边下载边播放
 */
- (void)playWithURL:(NSURL *)url isSupportCache:(BOOL)isSupportCache;

/**
 设置播放时候的加载动画View,默认为系统UIActivityIndicatorView
 */
@property (nonatomic,strong) UIView<LZBVideoPlayerLoadingDelegate> *loadingView;

@end
