//
//  LZBVideoPlayer.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "LZBVideoURLResourceLoader.h"
#import "LZBPlayerBottomControlView.h"
#import "LZBVideoFileManger.h"

static LZBVideoPlayer *_instance;

NSString *const LZBVideoPlayerPropertyStatus = @"status";
NSString *const LZBVideoPlayerPropertyPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";


@interface LZBVideoPlayer() <LZBVideoURLResourceLoaderDelegate>

@property (nonatomic, strong)  NSURL *playPathURL; //播放视频url
@property (nonatomic, assign)  BOOL isAddObserver; //是否添加了监听，只增加一次

@property (nonatomic, strong)  AVURLAsset *videoURLAsset;  //当前播放视频网络请求URL资源
@property (nonatomic, strong) AVPlayerItem *currentPlayerItem; //当前正在播放视频的Item
@property (nonatomic, strong) AVPlayer *currentPlayer; //当前播放器

@property (nonatomic, strong) LZBVideoURLResourceLoader *resourceLoader;  // 数据源

@property (nonatomic, assign) BOOL   isPauseByUser; //是否被用户暂停

@end

@implementation LZBVideoPlayer
#pragma mark -Open  API

- (void)playWithURL:(NSURL *)url isSupportCache:(BOOL)isSupportCache
{
    //1.检测容错
    if( self.currentPlayer && [self.playPathURL isEqual:url])
    {
        [self resume];
        return;
    }
    
    if(![self checkIsCorrectWithURL:url]) return;
   
    //2.检测URL本地还是网络,播放URL
    if(![self.playPathURL.absoluteString hasPrefix:@"http"])
    {
       //本地视频
        [self playerLocationWithDownLoadVideo:self.playPathURL];
    }
    else
    {
        //采用resourceLoader给播放器补充数据
        NSURL *tempVideoURL = nil;
        if(isSupportCache)
            tempVideoURL = [self.resourceLoader getVideoResourceLoaderSchemeWithURL:self.playPathURL];
        else
            tempVideoURL = self.playPathURL;
        self.videoURLAsset  = [AVURLAsset URLAssetWithURL:tempVideoURL options:nil];
        [self.videoURLAsset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
        
        self.currentPlayerItem  = [AVPlayerItem playerItemWithAsset:self.videoURLAsset];
        if (!self.currentPlayer) {
            self.currentPlayer = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
        } else {
            [self.currentPlayer replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
        }
        self.currentPlayerLayer   = [AVPlayerLayer playerLayerWithPlayer:self.currentPlayer];
    }
}

- (void)resume
{
    if(self.currentPlayerItem == nil) return;
    [self.currentPlayer play];
    self.isPauseByUser = NO;
    if(self.currentPlayer.currentItem && self.currentPlayer.currentItem.playbackLikelyToKeepUp)
    {
        self.state = LZBVideoPlayerState_Playing;
    }
}

- (void)pause
{
    if(self.currentPlayerItem == nil) return;
    [self.currentPlayer pause];
    self.isPauseByUser = YES;
    if(self.currentPlayer.currentItem)
        self.state = LZBVideoPlayerState_Pause;
}

- (void)stop
{
    if(self.currentPlayer == nil) return;
    [self.currentPlayer pause];
    [self.currentPlayer cancelPendingPrerolls];
    if(self.currentPlayer.currentItem)
        self.state = LZBVideoPlayerState_Stoped;
    self.currentPlayer = nil;
}

- (void)seekWithTimeDiffer:(NSTimeInterval)differ
{
    //1.获取总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    
    // 2.获取当前时长
    NSTimeInterval currentTimeSec = [self currentTime];
    
    //3.计算快进和快退时长
    NSTimeInterval result = currentTimeSec + differ;
    if(result < 0) result = 0;
    if(result > totalTimeSec) result =  totalTimeSec;
    
    //4.播放
    [self seekWithProgress:result / totalTimeSec];

}


- (void)seekWithProgress:(CGFloat)progress
{
     if(progress < 0 || progress > 1) return;
    //1.获取总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    
    //2..需要播放的进度
    NSTimeInterval requireTimeSec = totalTimeSec * progress;
    CMTime currentTime = CMTimeMake(requireTimeSec, 1.0);
    
    //3.播放
     __weak typeof(self) weakSelf = self;
    [self.currentPlayer seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if(finished){
            NSLog(@"拖动到-----%f",CMTimeGetSeconds(currentTime));
            //播放结束的时候，不会自动调用播放，需要手动调用
            [weakSelf resume];
        }
        else
        {
            NSLog(@"取消加载");
        }
    }];
}
#pragma mark - KVO监听

//收到内存警告
-(void)receiveMemoryWarning{
    NSAssert(1, @"receiveMemoryWarning, 内存警告");
    [self stop];
}

//进入后台
- (void)appDidEnterBackground{
    if (self.stopWhenAppDidEnterBackground) {
        [self pause];
    }
}

//进入前台
- (void)appDidEnterPlayGround{
    [self resume];
}

//播放完成
- (void)playerItemDidPlayToEnd:(NSNotification *)notification{
    [self stop];
}

//KVO属性
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
 
    AVPlayerItem *item = (AVPlayerItem *)object;
    if([keyPath isEqualToString:LZBVideoPlayerPropertyStatus])  //监听播放器的状态
    {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        [self monitorPropertyStatus:status];
    }
    else if ([keyPath isEqualToString:LZBVideoPlayerPropertyPlaybackLikelyToKeepUp]) //监听播放器加载过程
    {
        BOOL keepUp = [change[NSKeyValueChangeNewKey] integerValue];
        [self monitorPropertyPlaybackLikelyToKeepUpWithItem:item isKeepUp:keepUp];
    }
    else
    {
         //不做处理
    }
}

- (void)monitorPropertyStatus:(AVPlayerItemStatus)itemStatus
{
    switch (itemStatus) {
        case AVPlayerItemStatusReadyToPlay:{
            //准备播放
            self.state = LZBVideoPlayerState_ReadyToPlay;
            [self resume];
        }
            break;
        case AVPlayerItemStatusUnknown:
        case AVPlayerItemStatusFailed:{
            NSLog(@"数据准备失败, 无法播放");
            self.state = LZBVideoPlayerState_Failed;
        }
            break;
        default:
            break;
    }
}
- (void)monitorPropertyPlaybackLikelyToKeepUpWithItem:(AVPlayerItem *)playerItem isKeepUp:(BOOL)keepUp
{
    if (keepUp){
        //如果不是用户手动暂停，可以播放，用户手动操作级别最高
        if(!self.isPauseByUser)
        {
            [self resume];
        }
        NSLog(@"资源已经加载的差不多，可以播放了");
    }
    else
    {
        NSLog(@"资源不够，还要继续加载");
        self.state = LZBVideoPlayerState_Loading;
    }
}




#pragma mark - 数据传递/事件处理
-(void)setCurrentPlayerLayer:(AVPlayerLayer *)currentPlayerLayer
{
    if(_currentPlayerLayer != nil)
    {
        [_currentPlayerLayer removeFromSuperlayer];
    }
    _currentPlayerLayer = currentPlayerLayer;
}


- (void)setState:(LZBVideoPlayerState)state
{
    if(_state == state)return;
    _state = state;
    //代理监听回调
    if([self.delegate respondsToSelector:@selector(videoPlayer:didStateChange:)])
    {
       [self.delegate videoPlayer:self didStateChange:_state];
    }
}

//总时间
- (NSTimeInterval)totalTime
{
    CMTime totalTime = self.currentPlayer.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if(isnan(totalTimeSec))
        return 0;
    return totalTimeSec;
}

- (NSString *)totalTimeFormat
{
    long totalFmtTime = ceil(self.totalTime);
    return [self timeFormatWithTime:totalFmtTime];
}
//当前时间
- (NSTimeInterval)currentTime
{
    CMTime currentTime = self.currentPlayer.currentItem.currentTime;
    NSTimeInterval currentTimeSec = CMTimeGetSeconds(currentTime);
    if(isnan(currentTimeSec))
        return 0;
    return currentTimeSec;
}

- (NSString *)currentTimeFormat
{
    long currentFmtTime = ceil(self.currentTime);
    return [self timeFormatWithTime:currentFmtTime];
}

//缓存进度
- (CGFloat)loadedProgress
{
    CMTimeRange timeRange = [[self.currentPlayer.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    CMTime loadTime =  CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    if(isnan(loadTimeSec))
        return 0;
    return loadTimeSec / self.totalTime;
}


//当前进度
- (CGFloat)progress
{
    if(self.totalTime == 0)
        return 0;
    
    return self.currentTime / self.totalTime;
}
//倍速
- (void)setRate:(float)rate
{
    self.currentPlayer.rate = rate;
}
- (float)rate
{
    return self.currentPlayer.rate;
}
//静音
- (void)setMuted:(BOOL)muted
{
    self.currentPlayer.muted = muted;
}
- (BOOL)muted
{
    return self.currentPlayer.muted;
}
//声音
- (void)setVolume:(float)volume
{
    if(volume < 0 || volume > 1) return;
    
    if(volume > 0)
        [self setMuted:NO];
    
    self.currentPlayer.volume = volume;
}

- (float)volume{
    return self.currentPlayer.volume;
}


#pragma mark - LZBVideoURLResourceLoaderDelegate

- (void)didFinishSucessLoadedWithManger:(LZBVideoDownLoadManger *)manger saveVideoPath:(NSString *)videoPath
{
     //检测磁盘是否够用
}

- (void)didFailLoadedWithManger:(LZBVideoDownLoadManger *)manger withError:(NSError *)error
{
  
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

- (NSString *)timeFormatWithTime:(long)time
{
    
    NSString *timeFmtStr = nil;
    if (time < 3600) {
        timeFmtStr =  [NSString stringWithFormat:@"%02li:%02li",lround(floor(time/60.f)),lround(floor(time/1.f))%60];
    } else {
        timeFmtStr =  [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(time/3600.f)),lround(floor(time%3600)/60.f),lround(floor(time/1.f))%60];
    }
    return timeFmtStr;
}

- (void)playerLocationWithDownLoadVideo:(NSURL *)videoURL
{
    self.videoURLAsset  = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    self.currentPlayerItem  = [AVPlayerItem playerItemWithAsset:self.videoURLAsset];
    if (!self.currentPlayer) {
        self.currentPlayer = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
    } else {
        [self.currentPlayer replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
    }
    self.currentPlayerLayer   = [AVPlayerLayer playerLayerWithPlayer:self.currentPlayer];
}

- (void)addObserversOnce
{
    if(!self.isAddObserver)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.isAddObserver = YES;
    }
}


- (void)setCurrentPlayerItem:(AVPlayerItem *)currentPlayerItem
{
    if(_currentPlayerItem != nil) //移除之前的监听
    {
        [_currentPlayerItem removeObserver:self forKeyPath:LZBVideoPlayerPropertyStatus];
        [_currentPlayerItem removeObserver:self forKeyPath:LZBVideoPlayerPropertyPlaybackLikelyToKeepUp];
        
    }
    
    _currentPlayerItem = currentPlayerItem;
    //增加现在的监听
    [_currentPlayerItem addObserver:self forKeyPath:LZBVideoPlayerPropertyStatus options:NSKeyValueObservingOptionNew context:nil];
    [_currentPlayerItem addObserver:self forKeyPath:LZBVideoPlayerPropertyPlaybackLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
}


//复位原来的参数
- (void)resetParam
{
    [self stop];
    if(self.currentPlayerLayer != nil)
    {
        [self.currentPlayerLayer removeFromSuperlayer];
        self.currentPlayerLayer = nil;
    }
    
    [self.videoURLAsset.resourceLoader setDelegate:nil queue:dispatch_get_main_queue()];
    self.videoURLAsset = nil;
    self.currentPlayerItem = nil;
    self.currentPlayer = nil;
    self.playPathURL = nil;
    [self.resourceLoader invalidDownloader];
    self.resourceLoader = nil;
}



#pragma mark - init
- (instancetype)init
{
    if(self = [super init])
    {
        self.stopWhenAppDidEnterBackground = YES;
        self.maxCacheSize = 1024*1024*1024;
        [self addObserversOnce];
    }
    return self;
}

+ (instancetype)shareInstance
{
    if(_instance == nil)
    {
        _instance = [[self alloc]init];
    }
    return _instance;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    if(_instance == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [super allocWithZone:zone];
        });
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone{
    return _instance;
}
- (id)mutableCopyWithZone:(NSZone *)zone{
    return _instance;
}

#pragma mark- lazy
- (LZBVideoURLResourceLoader *)resourceLoader
{
  if(_resourceLoader == nil)
  {
     _resourceLoader = [[LZBVideoURLResourceLoader alloc]init];
      _resourceLoader.delegate = self;
  }
    return _resourceLoader;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self resetParam];
    
}

@end
