//
//  LZBVideoPlayer.h
//  LZBVideoPlayer
//
//  Created by zibin on 2017/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol LZBVideoPlayerLoadingDelegate <NSObject>
@required
- (void)startAnimating;
- (void)stopAnimating;

@end

typedef NS_ENUM(NSInteger,LZBVideoPlayerState)
{
    LZBVideoPlayerState_None = 0,  //无状态
    LZBVideoPlayerState_Loading = 1, //加载中状态
    LZBVideoPlayerState_Playing = 2, //正在播放状态
    LZBVideoPlayerState_Stoped = 3, //停止状态
    LZBVideoPlayerState_Pause = 4,  //暂停状态
    
};


@interface LZBVideoPlayer : NSObject


#pragma mark - Open  Protery

/**
  默认是YES
 */
@property (nonatomic, assign) BOOL stopWhenAppDidEnterBackground;

/**
  是否支持下载完成，保存到沙盒中，默认是YES
 */
@property (nonatomic, assign) BOOL isSupportDownLoadedCache;


/**
  设置播放时候的加载动画View,默认为系统UIActivityIndicatorView
 */
@property (nonatomic,strong) UIView<LZBVideoPlayerLoadingDelegate> *loadingView;

/**
  isSupportDownLoadedCache = YES 有效
  最大磁盘缓存. 默认为 1G, 超过 1G 将自动清空所有视频磁盘缓存.
 */
@property(nonatomic, assign)unsigned long long  maxCacheSize;

/**
 视频播放状态
 */
@property (nonatomic, assign, readonly) LZBVideoPlayerState state;

/**
 缓冲进度
 */
@property (nonatomic, assign,readonly) CGFloat       loadedProgress;

/**
  视频总时间
 */
@property (nonatomic, assign,readonly) CGFloat       totalTime;

/**
 当前播放时间
 */
@property (nonatomic, assign,readonly) CGFloat       currentTime;

/**
 播放进度 0~1
 */
@property (nonatomic, assign,readonly) CGFloat       progress;



#pragma mark -Open  API

/**
 实例化

 @return LZBVideoPlayer
 */
+ (instancetype)sharedInstance;

/**
 传入播放的路径，以及需要显示类的父类
 
 @param url 可以传入本地路径、也可以传入网络路径，自动播放
 @param showView 需要显示类的父类
 */
- (void)playWithURL:(NSURL *)url showInView:(UIView *)showView;

/**
  继续播放
 */
- (void)resume;

/**
 暂停播放
 */
- (void)pause;

/**
  停止播放
 */
- (void)stop;

/**
  isSupportDownLoadedCache = YES 有效
  异步清除指定URL的缓存视频文件
 @param url 缓存路径
 */
- (void)clearVideoCacheForUrl:(NSURL *)url;

/**
 *
 isSupportDownLoadedCache = YES 有效
 异步清除所有的缓存, 包括完整视频文件和临时视频文件
 */
-(void)clearAllVideoCache;




@end
