//
//  LZBVideoFileManger.h
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/27.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LZBVideoFileManger : NSObject

#pragma mark - cache操作

#pragma mark - Cache操作
/**
 根据URL,判断Cache文件是否存在
 
 @param url URL
 */
+ (BOOL)cacheFileExitWithURL:(NSURL *)url;

/**
 根据URL获取文件Cache路径
 
 @param url URL
 @return 文件路径
 */
+ (NSString *)cacheFilePathWithURL:(NSURL*)url;

/**
 根据URL获取文件Cache的大小
 
 @param url URL
 @return 文件路径
 */
+ (long long)cacheFileSizeWithURL:(NSURL*)url;


/**
 根据URL移除沙盒里面缓存数据

 @param url url
 */
+ (void)removeCacheWithURL:(NSURL*)url;

/**
 获取cache文件剩余空间
 */
+ (long long)cacheFreeDiskSpace;



#pragma mark - temp操作
/**
 根据URL,判断Temp文件是否存在
 
 @param url URL
 */
+ (BOOL)tempFileExitWithURL:(NSURL *)url;

/**
 根据URL获取文件Temp路径
 
 @param url URL
 @return 文件路径
 */
+ (NSString *)tempFilePathWithURL:(NSURL*)url;

/**
 根据URL获取文件Temp的大小
 
 @param url URL
 @return 文件路径
 */
+ (long long)tempFileSizeWithURL:(NSURL*)url;

/**
 根据URL移除文件
 
 @param url URL
 */
+ (void)removeTempWithURL:(NSURL*)url;

/**
 获取temp文件剩余空间
 */
+ (long long)tempFreeDiskSpace;



#pragma mark - common操作

/**
 根据URL移动文件 temp - > cache (异步)
 
 @param url URL
 */
+ (void)moveFileToCacheWithURL:(NSURL*)url;


/**
 根据URL获取contentType
 
 @param url URL
 @return 文件路径
 */
+ (NSString *)contentTypeWithURL:(NSURL*)url;


/**
 获取磁盘剩余存储空间
 */
+ (long long)sandboxFreeSizeFromDisk;

/**
 * 清除所有的缓存(异步), 包括完整视频文件和临时视频文件.
 */
+ (void)cleanAllVideoCache;

/**
 获取所有的视频文件大小（异步），包括完整视频文件和临时视频文件.
 */
+ (void)getAllVideoSize:(void(^)(unsigned long long total))compeletedOperation;

@end
