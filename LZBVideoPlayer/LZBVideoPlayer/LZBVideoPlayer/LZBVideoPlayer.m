//
//  LZBVideoPlayer.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "LZBVideoCachePathTool.h"
#import "LZBVideoURLResourceLoader.h"
#import "LZBCacheManger.h"
#import "LZBPlayerBottomControlView.h"

NSString *const LZBVideoPlayerPropertyStatus = @"status";
NSString *const LZBVideoPlayerPropertyPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";


@interface LZBVideoPlayer() <LZBVideoURLResourceLoaderDelegate>
{
    BOOL _isUserPause;  //用户手动暂停
}

@property (nonatomic, strong)  NSURL *playPathURL; //播放视频url
@property (nonatomic, assign)  BOOL isAddObserver; //是否添加了监听，只增加一次
@property (nonatomic, weak)   UIView *showSuperView; //显示在父类View

@property (nonatomic, strong)  AVURLAsset *videoURLAsset;  //当前播放视频网络请求URL资源
@property (nonatomic, strong) AVPlayerItem *currentPlayerItem; //当前正在播放视频的Item
@property (nonatomic, strong) AVPlayerLayer *currentPlayerLayer; //当前图像层
@property (nonatomic, strong) AVPlayer *currentPlayer; //当前播放器

@property (nonatomic, strong) LZBVideoURLResourceLoader *resourceLoader;  // 数据源
@property (nonatomic, assign) BOOL   isFinishLoad; //是否下载完毕
@property (nonatomic, assign) BOOL   isPauseByUser; //是否被用户暂停
@property (nonatomic, assign) BOOL    isLocalVideo; //是否播放本地文件

@property (nonatomic, strong) LZBPlayerBottomControlView *bottomControllView; //底部控制操作View

@property (nonatomic, strong) NSTimer *timer;  //定时刷新UI
@end

@implementation LZBVideoPlayer

+ (instancetype)sharedInstance
{
    return [[self alloc]init];
}

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
       [self addObserversOnce];
       [self startTimer];
   }
    return self;
}



#pragma mark -Open  API

- (void)playWithURL:(NSURL *)url showInView:(UIView *)showView
{
    //1.检测参数
    if(![self checkIsCorrectWithURL:url]) return;
    if(showView == nil) return;
    self.showSuperView = showView;
    
    if( self.currentPlayer && [self.playPathURL isEqual:url])
    {
        [self resume];
        
        return;
    }
    
    //2.检测URL本地还是网络,播放URL
    if(![self.playPathURL.absoluteString hasPrefix:@"http"])
    {
       //本地视频
        [self playerLocationWithDownLoadVideo:self.playPathURL showInView:showView];
    }
    else
    {
        //网络视频是否已经下载，如果已经下载，就直接播放本地
        NSString *videoName = [LZBVideoCachePathTool getFileNameWithURL:self.playPathURL];
        //从下载的文件路径中获取保存的文件夹
        NSString *folder = [LZBVideoCachePathTool getFilePathWithSaveCache];
        //拼接路径
        NSString *localFilePath = [folder stringByAppendingPathComponent:videoName];
        NSFileManager *fileManger = [NSFileManager defaultManager];
        //如果路径路径存在，则文件已经下载好，那么直接播放，如果未下载好，就从网络加载
        if([fileManger fileExistsAtPath:localFilePath])
        {
          self.playPathURL = [NSURL fileURLWithPath:localFilePath];
          [self playerLocationWithDownLoadVideo:self.playPathURL showInView:showView];
        }
        else
        {
            //采用resourceLoader给播放器补充数据
            NSURL *tempVideoURL = nil;
            self.resourceLoader = [[LZBVideoURLResourceLoader alloc]init];
            self.resourceLoader.delegate = self;
            if(self.isSupportDownLoadedCache)
                tempVideoURL = [self.resourceLoader getSchemeVideoURL:self.playPathURL];
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
            CGFloat currentPlayerLayerHeight = showView.bounds.size.height - [LZBPlayerBottomControlView getPlayerBottomHeight];
            self.currentPlayerLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, currentPlayerLayerHeight);
        }
        
    }
}

- (void)resume
{
    if(self.currentPlayerItem == nil) return;
    [self.currentPlayer play];
    _isUserPause = NO;
    if(self.currentPlayer.currentItem && self.currentPlayer.currentItem.playbackLikelyToKeepUp)
    {
        self.state = LZBVideoPlayerState_Playing;
    }
}

- (void)pause
{
    if(self.currentPlayerItem == nil) return;
    [self.currentPlayer pause];
    _isUserPause = YES;
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

- (void)clearVideoCacheForUrl:(NSURL *)url
{
    [LZBCacheManger clearVideoFromCacheWithURL:url];
}

-(void)clearAllVideoCache
{
    [LZBCacheManger clearAllVideoCache];
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


#pragma mark - KVO状态监听处理
- (void)monitorPropertyStatus:(AVPlayerItemStatus)itemStatus
{
    switch (itemStatus) {
        case AVPlayerItemStatusReadyToPlay:{
            //准备播放
            self.state = LZBVideoPlayerState_ReadyToPlay;
            // 显示图像逻辑
            [self setupUI];
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
        if(!_isUserPause)
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



#pragma mark - 定时器刷新UI
- (void)startTimer
{
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateUI
{
    //更新UI
    [self updateCurrentTimeLabel:self.currentTime];  //当前时间
    [self updateTotalTimeLabel:self.totalTime]; //当前总时间
    [self.bottomControllView.progressView setProgress:self.loadedProgress animated:YES]; //当前加载进度
    [self updateSlideValue:self.progress]; //当前播放进度
}

#pragma mark - 数据传递/事件处理

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

//总时间
- (CGFloat)totalTime
{
    CMTime totalTime = self.currentPlayer.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if(isnan(totalTimeSec))
        return 0;
    return totalTimeSec;
}
//当前时间
- (CGFloat)currentTime
{
    CMTime currentTime = self.currentPlayer.currentItem.currentTime;
    NSTimeInterval currentTimeSec = CMTimeGetSeconds(currentTime);
    if(isnan(currentTimeSec))
        return 0;
    return currentTimeSec;
}
//当前进度
- (CGFloat)progress
{
    if(self.totalTime == 0)
        return 0;
    
    return self.currentTime / self.totalTime;
}


#pragma mark - LZBVideoURLResourceLoaderDelegate

- (void)didFinishSucessLoadedWithManger:(LZBVideoDownLoadManger *)manger saveVideoPath:(NSString *)videoPath
{
     //检测磁盘是否够用
}

- (void)didFailLoadedWithManger:(LZBVideoDownLoadManger *)manger withError:(NSError *)error
{
  
}

#pragma mark - UI -Handle
//初始化
- (void)setupUI
{
    [self.showSuperView.layer addSublayer:self.currentPlayerLayer];
    [self.showSuperView addSubview:self.bottomControllView];
    self.bottomControllView.frame = CGRectMake(0, CGRectGetMaxY(self.currentPlayerLayer.frame), self.showSuperView.bounds.size.width, self.showSuperView.bounds.size.height - CGRectGetMaxY(self.currentPlayerLayer.frame));
}

//更新当前时间
- (void)updateCurrentTimeLabel:(CGFloat)currentTime
{
    long videoCurrentTime = ceil(currentTime);
    
    NSString *currentStr = nil;
    if (videoCurrentTime < 3600) {
        currentStr =  [NSString stringWithFormat:@"%02li:%02li",lround(floor(videoCurrentTime/60.f)),lround(floor(videoCurrentTime/1.f))%60];
    } else {
        currentStr =  [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(videoCurrentTime/3600.f)),lround(floor(videoCurrentTime%3600)/60.f),lround(floor(videoCurrentTime/1.f))%60];
    }
    self.bottomControllView.currentTimeLabel.text = currentStr;
  
}

//更新总共时间
- (void)updateTotalTimeLabel:(CGFloat)totalTime
{
    long videoTotalTime = ceil(totalTime);
    
    NSString *totalStr = nil;
    if (videoTotalTime < 3600) {
        totalStr =  [NSString stringWithFormat:@"%02li:%02li",lround(floor(videoTotalTime/60.f)),lround(floor(videoTotalTime/1.f))%60];
    } else {
        totalStr =  [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(videoTotalTime/3600.f)),lround(floor(videoTotalTime%3600)/60.f),lround(floor(videoTotalTime/1.f))%60];
    }
    self.bottomControllView.totalTimeLabel.text = totalStr;
}

//更新滑块的进度
- (void)updateSlideValue:(CGFloat)value
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

- (void)playerLocationWithDownLoadVideo:(NSURL *)videoURL  showInView:(UIView *)showView
{
    self.videoURLAsset  = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    self.currentPlayerItem  = [AVPlayerItem playerItemWithAsset:self.videoURLAsset];
    if (!self.currentPlayer) {
        self.currentPlayer = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
    } else {
        [self.currentPlayer replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
    }
    self.currentPlayerLayer   = [AVPlayerLayer playerLayerWithPlayer:self.currentPlayer];
    CGFloat currentPlayerLayerHeight = showView.bounds.size.height - [LZBPlayerBottomControlView getPlayerBottomHeight];
    self.currentPlayerLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, currentPlayerLayerHeight);
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

- (void)setCurrentPlayerLayer:(AVPlayerLayer *)currentPlayerLayer
{
  if(_currentPlayerLayer != nil)
  {
      [_currentPlayerLayer removeFromSuperlayer];
  }
    _currentPlayerLayer = currentPlayerLayer;
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
    [self.resourceLoader invalidDownload];
    self.resourceLoader = nil;
}


//检测剩余的空间
- (void)checkDiskSize{
    __weak typeof(self) weakSelf = self;
    [LZBCacheManger getAllVideoSize:^(unsigned long long total) {
         if(total > weakSelf.maxCacheSize)
             [weakSelf clearAllVideoCache];
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self resetParam];
    [self stopTimer];
}


#pragma mark- lazy
- (LZBPlayerBottomControlView *)bottomControllView
{
  if(_bottomControllView == nil)
  {
      _bottomControllView = [LZBPlayerBottomControlView new];
  }
    return _bottomControllView;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PlayerImage" ofType:@"bundle"];
    return [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", imageName]]];
}

@end
