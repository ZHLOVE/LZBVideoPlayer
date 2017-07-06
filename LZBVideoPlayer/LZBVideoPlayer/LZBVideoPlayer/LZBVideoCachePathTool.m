//
//  LZBVideoCachePathTool.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoCachePathTool.h"

@implementation LZBVideoCachePathTool
/**
 获取临时文件路径
 */
+ (NSString *)getFilePathWithTempCache
{
    return [self getFilePathWithAppendingString:lzb_tempVideoPath];
}

/**
 获取保存文件路径，完整
 */
+ (NSString *)getFilePathWithSaveCache
{
    return [self getFilePathWithAppendingString:lzb_saveVideoPath];
}

/**
 根据路径获取文件名字,视频的名字
 */
+ (NSString *)getFileNameWithURL:(NSURL *)url
{
    return [url.absoluteString.lastPathComponent componentsSeparatedByString:@"?"].firstObject;
}

+(NSString *)getFilePathWithAppendingString:(NSString *)str
{
    NSFileManager *manger = [NSFileManager defaultManager];
    
    //创建路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingString:str];
    
    //如果文件路径不存在，那么就创建文件夹
    if(![manger fileExistsAtPath:path])
    {
        [manger createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}
@end
