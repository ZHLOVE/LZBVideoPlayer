//
//  LZBVideoCachePathTool.h
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
  获取存取视频路径
 */
static NSString *lzb_tempVideoPath = @"/LZBVideoPlayer_Temp"; //临时文件夹路径
static NSString *lzb_saveVideoPath = @"/LZBVideoPlayer_Save";  //完成文件夹路径

@interface LZBVideoCachePathTool : NSObject

/**
  获取临时文件夹路径
 */
+ (NSString *)getFilePathWithTempCache;

/**
  获取保存文件夹路径，完整
 */
+ (NSString *)getFilePathWithSaveCache;


/**
  根据路径获取文件名字，根据路径获取文件名字,视频的名字
 */
+ (NSString *)getFileNameWithURL:(NSURL *)url;
@end
