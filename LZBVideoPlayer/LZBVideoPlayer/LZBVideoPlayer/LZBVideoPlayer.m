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

@interface LZBVideoPlayer() <LZBVideoURLResourceLoaderDelegate>

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

@property(nonatomic, strong) LZBVideoURLResourceLoader *resourceLoader;  // 数据源

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
    self.currentPlayerLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, showView.bounds.size.height);
}
@end
