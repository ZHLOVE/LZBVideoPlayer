//
//  LZBVideoPlayer.h
//  LZBVideoPlayer
//
//  Created by zibin on 2016/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class LZBVideoPlayer;

typedef NS_ENUM(NSInteger,LZBVideoPlayerState)
{
    LZBVideoPlayerState_None        = 0,  //无状态
    LZBVideoPlayerState_Loading     = 1, //加载中状态
    LZBVideoPlayerState_ReadyToPlay = 2,  //准备播放
    LZBVideoPlayerState_Playing     = 3, //正在播放状态
    LZBVideoPlayerState_Stoped      = 4, //停止状态
    LZBVideoPlayerState_Pause       = 5,  //暂停状态
    LZBVideoPlayerState_Failed      = 6,  //失败状态
    
};

@protocol LZBVideoPlayerDelegate <NSObject>

//代理监听状态改变
- (void)videoPlayer:(LZBVideoPlayer *)player didStateChange:(LZBVideoPlayerState)state;

@end




@interface LZBVideoPlayer : NSObject


#pragma mark - Open  Protery

/**
 是否静音 - 双向
 */
@property (nonatomic, assign) BOOL muted;

/**
 倍速控制 - 双向
 */
@property (nonatomic, assign) float rate;

/**
 音量控制 - 双向
 */
@property (nonatomic, assign) float volume;

/**
 播放器监听代理 - 双向
 */
@property (nonatomic, weak)  id <LZBVideoPlayerDelegate> delegate;

/**
 默认是YES - 双向
 */
@property (nonatomic, assign) BOOL stopWhenAppDidEnterBackground;

/**
 最大磁盘缓存. 默认为 1G, 超过 1G 将自动清空所有视频磁盘缓存,isSupportDownLoadedCache = YES 有效
 */
@property (nonatomic, assign) unsigned long long  maxCacheSize;

/**
 播放层
 */
@property (nonatomic, strong, readonly) AVPlayerLayer *currentPlayerLayer;

/**
 视频播放状态
 */
@property (nonatomic, assign, readonly) LZBVideoPlayerState state;

/**
  视频总时间
 */
@property (nonatomic, assign, readonly) NSTimeInterval   totalTime;
@property (nonatomic, strong, readonly) NSString *totalTimeFormat;

/**
 当前播放时间
 */
@property (nonatomic, assign, readonly) NSTimeInterval   currentTime;
@property (nonatomic, strong, readonly) NSString *currentTimeFormat;

/**
 播放进度 0~1
 */
@property (nonatomic, assign, readonly) CGFloat   progress;

/**
 缓冲进度
 */
@property (nonatomic, assign, readonly) CGFloat   loadedProgress;




#pragma mark -Open  API

/**
 实例化

 @return LZBVideoPlayer
 */
+ (instancetype)shareInstance;


/**
 传入播放的路径，以及需要显示类的父类
 
 @param url 可以传入本地路径、也可以传入网络路径，自动播放
 @param isSupportCache 是否支持边下载边播放
 */
- (void)playWithURL:(NSURL *)url  isSupportCache:(BOOL)isSupportCache;

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
 快进  快退 differ
 */
- (void)seekWithTimeDiffer:(NSTimeInterval)differ;

/**
 指定播放进度播放
 */
- (void)seekWithProgress:(CGFloat)progress;





@end
