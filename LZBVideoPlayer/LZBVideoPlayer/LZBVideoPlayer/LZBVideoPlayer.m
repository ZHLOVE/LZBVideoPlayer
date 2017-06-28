//
//  LZBVideoPlayer.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface LZBVideoPlayer()

@property (nonatomic, assign) LZBVideoPlayerState state; //视频播放状态
@property (nonatomic, assign) CGFloat   loadedProgress; //缓冲进度
@property (nonatomic, assign) CGFloat   totalTime;  //视频总时间
@property (nonatomic, assign) CGFloat   currentTime; //当前播放时间
@property (nonatomic, assign) CGFloat    progress; // 播放进度 0~1
@property (nonatomic, strong)  NSURL *playPathURL; //播放视频url
@property (nonatomic, assign)  BOOL isAddObserver; //是否添加了监听，只增加一次
@property (nonatomic, weak)   UIView *showSuperView; //显示在父类View

@property(nonatomic, strong)  AVURLAsset *videoURLAsset;  //当前播放视频网络请求URL资源
@property (nonatomic, strong) AVPlayerItem *currentPlayerItem; //当前正在播放视频的Item
@property (nonatomic, strong) AVPlayerLayer *currentPlayerLayer; //当前图像层
@property (nonatomic, strong) AVPlayer *currentPlayer; //当前播放器

@end

@implementation LZBVideoPlayer
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static id _shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [super allocWithZone:zone];
    });
    return _shareInstance;
}
- (instancetype)init
{
   if(self = [super init])
   {
       self.stopWhenAppDidEnterBackground = YES;
       self.isSupportDownLoadedCache = YES;
       self.maxCacheSize = 1024*1024*1024;
       self.state = LZBVideoPlayerState_Stoped;
       self.loadedProgress = 0;
       self.totalTime = 0;
       self.currentTime =0;
       self.progress = 0;
       [self addObserversOnce];
   }
    return self;
}

- (void)addObserversOnce
{
   if(!self.isAddObserver)
   {
      
   }
    
}

#pragma mark -Open  API
+ (instancetype)sharedInstance
{
    return [[self alloc]init];
}

- (void)playWithURL:(NSURL *)url showInView:(UIView *)showView
{
    //1.检测参数
    if(![self checkIsCorrectWithURL:url]) return;
    if(showView == nil) return;
    self.showSuperView = showView;
    
    //2.检测URL本地还是网络
    if(![self.playPathURL.absoluteString hasPrefix:@"http"])
    {
       //本地视频
        self.videoURLAsset  = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currentPlayerItem  = [AVPlayerItem playerItemWithAsset:self.videoURLAsset];
        if (!self.currentPlayer) {
            self.currentPlayer = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
        } else {
            [self.currentPlayer replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
        }
        self.currentPlayerLayer   = [AVPlayerLayer playerLayerWithPlayer:self.currentPlayer];
        self.currentPlayerLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, showView.bounds.size.height);
    }
    else
    {
        //网络视频
        
    }
    
}

#pragma mark - pravite
- (BOOL)checkIsCorrectWithURL:(NSURL *)url
{
    if([url isKindOfClass:[NSURL class]])
    {
       if(url.absoluteString.length == 0)
           return NO;
        self.playPathURL = url;
    }
    else if ([url isKindOfClass:[NSString class]])
    {
       NSString *string = (NSString *)url;
        if(string.length == 0)
            return NO;
        self.playPathURL = [NSURL URLWithString:string];
    }
    return YES;
}
@end
