//
//  LZBCacheManger.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBCacheManger.h"
#import "LZBVideoCachePathTool.h"
#import <sys/param.h>
#import <sys/mount.h>

@implementation LZBCacheManger
+ (void)clearVideoFromCacheWithURL:(NSURL *)cacheURL
{
    //1.检测URL是否正确
    if([cacheURL isKindOfClass:[NSURL class]])
    {
       if(cacheURL.absoluteString.length == 0)
           return;
    }
    
    if([cacheURL isKindOfClass:[NSString class]])
    {
        NSString *cacheString = (NSString *)cacheURL;
        if (cacheString.length==0) return;
        cacheURL = [NSURL URLWithString:cacheString];
    }
    
    //2.通过URL获取文件路径
    NSString *saveFilePath = [LZBVideoCachePathTool getFilePathWithSaveCache];
    NSString *saveFullPath = [saveFilePath stringByAppendingPathComponent:[LZBVideoCachePathTool getFileNameWithURL:cacheURL]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //3.判断文件路径是否存在
    if([fileManager fileExistsAtPath:saveFullPath])
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [fileManager removeItemAtPath:saveFullPath error:nil];
        });
    }
}


+(void)clearAllVideoCache
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempFilePath = [LZBVideoCachePathTool getFilePathWithTempCache];
    NSString *saveFilePath = [LZBVideoCachePathTool getFilePathWithSaveCache];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [fileManager removeItemAtPath:tempFilePath error:nil];
        [fileManager removeItemAtPath:saveFilePath error:nil];
    });
    
    
}


+ (void)getAllVideoSize:(void(^)(unsigned long long total))compeletedOperation
{
    NSString *tempFilePath = [LZBVideoCachePathTool getFilePathWithTempCache];
    NSString *saveFilePath = [LZBVideoCachePathTool getFilePathWithSaveCache];
    NSArray  *directoryPathArr = @[tempFilePath,saveFilePath];
    [self getSizeWithDirectoryPath:directoryPathArr completion:^(long long totalSize) {
         if(compeletedOperation)
             compeletedOperation(totalSize);
    }];
}


+ (unsigned long long)getFreeSizeFromDisk
{
    //获取磁盘大小、剩余空间
    struct statfs buf;
    unsigned long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
}


#pragma mark - private
+ (void)getSizeWithDirectoryPath:(NSArray *)directoryPathArr completion:(void(^)(long long))completionBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSInteger totalSize = 0;
        for (NSString *filePath in directoryPathArr) {
            BOOL isDirError;
            BOOL isFile = [manager fileExistsAtPath:filePath isDirectory:&isDirError];
            if (!isFile || !isDirError) {
                NSException *exc = [NSException exceptionWithName:@"FilePathError" reason:@"File not exist." userInfo:nil];
                [exc raise];
            }
            
            //获取文件目录的子目录
            NSArray *subPaths = [manager subpathsAtPath:filePath];
            for (NSString *subPath in subPaths) {
                NSString *fullPath = [filePath stringByAppendingPathComponent:subPath];
                if ([fullPath containsString:@".DS"]) continue;
                BOOL isDirectory;
                BOOL isFile = [manager fileExistsAtPath:fullPath isDirectory:&isDirectory];
                if (!isFile || isDirectory) continue;
                NSDictionary *attr = [manager attributesOfItemAtPath:fullPath error:nil];
                totalSize += [attr fileSize];
            }
        }
        
        //计算结果返回处理
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completionBlock)
                completionBlock(totalSize);
        });
    });
}
@end
