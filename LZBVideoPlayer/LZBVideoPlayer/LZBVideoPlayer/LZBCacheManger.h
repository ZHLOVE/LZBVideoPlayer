//
//  LZBCacheManger.h
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LZBCacheManger : NSObject

/**
 清理保存的指定URL的视频文件（异步）

 @param cacheURL 文件路径
 */
+ (void)clearVideoFromCacheWithURL:(NSURL *)cacheURL;


/**
 * 清除所有的缓存(异步), 包括完整视频文件和临时视频文件.
 */
+(void)clearAllVideoCache;


/**
 获取所有的视频文件大小（异步），包括完整视频文件和临时视频文件.
 */
+ (void)getAllVideoSize:(void(^)(unsigned long long total))compeletedOperation;

/**
  获取磁盘剩余存储空间
 */
+ (unsigned long long)getFreeSizeFromDisk;
@end
