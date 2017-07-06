//
//  LZBVideoURLResourceLoader.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoURLResourceLoader.h"
#import "LZBVideoCachePathTool.h"

@interface LZBVideoURLResourceLoader()


/**
  soure URL 的 scheme
 */
@property(nonatomic, strong) NSString *scheme;

/**
 * 视频路径
 */
@property (nonatomic, strong) NSString *videoPath;

@end

@implementation LZBVideoURLResourceLoader

#pragma mark- API

- (NSURL *)getSchemeVideoURL:(NSURL *)url
{
    
    // NSURLComponents用来替代NSMutableURL，可以readwrite修改URL
    // AVAssetResourceLoader通过你提供的委托对象去调节AVURLAsset所需要的加载资源。
    // 而很重要的一点是，AVAssetResourceLoader仅在AVURLAsset不知道如何去加载这个URL资源时才会被调用
    // 就是说你提供的委托对象在AVURLAsset不知道如何加载资源时才会得到调用。
    // 所以我们又要通过一些方法来曲线解决这个问题，把我们目标视频URL地址的scheme替换为系统不能识别的scheme
    NSURLComponents *component = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    self.scheme = component.scheme;
    component.scheme = @"lzbsystemNotKnow";
    
    //获取临时文件的视频路径
    NSString *tempFile = [LZBVideoCachePathTool getFilePathWithTempCache];
    NSString *videoName =[LZBVideoCachePathTool getFileNameWithURL:url];
    NSString *tempFilePath = [tempFile stringByAppendingPathComponent:videoName];
    self.videoPath = tempFilePath;
    
    return [component URL];
    
}
@end
