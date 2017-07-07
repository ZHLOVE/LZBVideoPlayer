//
//  LZBVideoPlayer.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "LZBVideoCachePathTool.h"
#import "LZBVideoURLResourceLoader.h"
#import "LZBCacheManger.h"

NSString *const LZBVideoPlayerPropertyStatus = @"status";
NSString *const LZBVideoPlayerPropertyLoadedTimeRanges = @"loadedTimeRanges";
NSString *const LZBVideoPlayerPropertyPlaybackBufferEmpty = @"playbackBufferEmpty";
NSString *const LZBVideoPlayerPropertyPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";


@interface LZBVideoPlayer() <LZBVideoURLResourceLoaderDelegate>

@property (nonatomic, assign) LZBVideoPlayerState playState; //视频播放状态
@property (nonatomic, assign) CGFloat   loadedProgress; //缓冲进度
@property (nonatomic, assign) CGFloat   totalTime;  //视频总时间
@property (nonatomic, assign) CGFloat   currentTime; //当前播放时间
@property (nonatomic, assign) CGFloat    progress; // 播放进度 0~1
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
       self.playState = LZBVideoPlayerState_Stoped;
       self.loadedProgress = 0;
       self.totalTime = 0;
       self.currentTime =0;
       self.progress = 0;
       [self addObserversOnce];
   }
    return self;
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
            self.resourceLoader = [[LZBVideoURLResourceLoader alloc]init];
            self.resourceLoader.delegate = self;
            NSURL *tempVideoURL = [self.resourceLoader getSchemeVideoURL:self.playPathURL];
            self.videoURLAsset  = [AVURLAsset URLAssetWithURL:tempVideoURL options:nil];
            [self.videoURLAsset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
            
            self.currentPlayerItem  = [AVPlayerItem playerItemWithAsset:self.videoURLAsset];
            if (!self.currentPlayer) {
                self.currentPlayer = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
            } else {
                [self.currentPlayer replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
            }
            self.currentPlayerLayer   = [AVPlayerLayer playerLayerWithPlayer:self.currentPlayer];
            self.currentPlayerLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, showView.bounds.size.height);
        }
        
    }
    
}

- (void)resume
{
    if(self.currentPlayerItem == nil) return;
    [self.currentPlayer play];
}

- (void)pause
{
    if(self.currentPlayerItem == nil) return;
    [self.currentPlayer pause];
}

- (void)stop
{
    if(self.currentPlayer == nil) return;
    [self.currentPlayer pause];
    [self.currentPlayer cancelPendingPrerolls];
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
        [self monitorPropertyStatus:item.status];
    }
    else if ([keyPath isEqualToString:LZBVideoPlayerPropertyLoadedTimeRanges]) //监听播放器的下载进度
    {
        [self monitorPropertyLoadedTimeRangesWithItem:item];
    }
    else if ([keyPath isEqualToString:LZBVideoPlayerPropertyPlaybackBufferEmpty]) //监听播放器在缓冲数据的状态
    {
        [self monitorPropertyPlaybackBufferEmptyWithItem:item];
    }
    else if ([keyPath isEqualToString:LZBVideoPlayerPropertyPlaybackLikelyToKeepUp]) //监听播放器下载完成
    {
        [self monitorPropertyPlaybackLikelyToKeepUpWithItem:item];
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
            // 显示图像逻辑
            [self.currentPlayer play];
//            self.player.muted = self.mute;
//            [self handleShowViewSublayers];
        }
            break;
        case AVPlayerItemStatusUnknown:
        case AVPlayerItemStatusFailed:{
            [self stop];
        }
            break;
        default:
            break;
    }
}

- (void)monitorPropertyLoadedTimeRangesWithItem:(AVPlayerItem *)playerItem
{
    NSArray<NSValue *> *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
    CMTime duration = playerItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration); //视频总长度
    self.loadedProgress = timeInterval / totalDuration;  //获取视频进度
    //更新UI
    
}

- (void)monitorPropertyPlaybackBufferEmptyWithItem:(AVPlayerItem *)playerItem
{
    if(playerItem.isPlaybackBufferEmpty)
    {
      //加载视频UI更新
        self.playState = LZBVideoPlayerState_Loading;
        [self bufferingForSeconds];
    }
}
- (void)monitorPropertyPlaybackLikelyToKeepUpWithItem:(AVPlayerItem *)playerItem
{
    if (playerItem.playbackLikelyToKeepUp){
        //停止加载视频动画UI更新
      
    }
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
//数据缓存加载中
- (void)bufferingForSeconds
{
   // playbackBufferEmpty会反复进入，在缓冲数据时, 为了防止播放器在等待数据时间过长时无法唤醒, 所以每隔2s段时间就唤醒一次播放器
    static BOOL isBuffering = NO;
    if(isBuffering) return;
    isBuffering = YES;
    //缓冲中先暂停
    [self.currentPlayer pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.currentPlayer play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
         isBuffering = NO;
        if (!self.currentPlayerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingForSeconds];
        }
    });
    
    
}
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
    self.currentPlayerLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, showView.bounds.size.height);
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
        [_currentPlayerItem removeObserver:self forKeyPath:LZBVideoPlayerPropertyLoadedTimeRanges];
        [_currentPlayerItem removeObserver:self forKeyPath:LZBVideoPlayerPropertyPlaybackBufferEmpty];
        [_currentPlayerItem removeObserver:self forKeyPath:LZBVideoPlayerPropertyPlaybackLikelyToKeepUp];
        
    }
    
    _currentPlayerItem = currentPlayerItem;
    //增加现在的监听
    [_currentPlayerItem addObserver:self forKeyPath:LZBVideoPlayerPropertyStatus options:NSKeyValueObservingOptionNew context:nil];
    [_currentPlayerItem addObserver:self forKeyPath:LZBVideoPlayerPropertyLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
     [_currentPlayerItem addObserver:self forKeyPath:LZBVideoPlayerPropertyPlaybackBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
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
}
@end
