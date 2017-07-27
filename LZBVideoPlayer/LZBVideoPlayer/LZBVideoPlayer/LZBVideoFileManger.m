//
//  LZBVideoFileManger.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/27.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoFileManger.h"
//获取contentType
#import <MobileCoreServices/MobileCoreServices.h>

#import <sys/param.h>
#import <sys/mount.h>
static NSString *lzb_tempVideoPath = @"/LZBVideoPlayerTempFolder"; //临时文件夹路径
static NSString *lzb_saveVideoPath = @"/LZBVideoPlayerSaveFolder";  //完成文件夹路径

@implementation LZBVideoFileManger

+ (BOOL)cacheFileExitWithURL:(NSURL *)url;
{
    NSString *cachePath = [self cacheFilePathWithURL:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}
+ (NSString *)cacheFilePathWithURL:(NSURL*)url
{
    NSString *cachePath = [[self getFileFolderCachePath] stringByAppendingPathComponent:url.lastPathComponent];
    return cachePath;
}
+ (long long)cacheFileSizeWithURL:(NSURL*)url
{
    //1.如果文件不存在，直接返回0
    if(![self cacheFileExitWithURL:url]) return 0;
    //2.如果文件存在，获取路径
    NSString *cachePath = [self cacheFilePathWithURL:url];
    //3.获取文件属性，文件大小
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
    return [fileInfo[NSFileSize] longLongValue];
}

+ (void)removeCacheWithURL:(NSURL*)url
{
    //1.如果文件存在，获取路径
    NSString *cachePath = [self cacheFilePathWithURL:url];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    });
}

+ (long long)cacheFreeDiskSpace
{
    NSDictionary *cacheInfo = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[self getFileFolderCachePath] error:nil];
    return [cacheInfo[NSFileSystemFreeSize] longLongValue];
}


+ (BOOL)tempFileExitWithURL:(NSURL *)url
{
    NSString *cachePath = [self tempFilePathWithURL:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}

+ (NSString *)tempFilePathWithURL:(NSURL*)url
{
    NSString *cachePath = [[self getFileFolderTempPath] stringByAppendingPathComponent:url.lastPathComponent];
    return cachePath;
}

+ (long long)tempFileSizeWithURL:(NSURL*)url
{
    //1.如果文件不存在，直接返回0
    if(![self tempFileExitWithURL:url]) return 0;
    //2.如果文件存在，获取路径
    NSString *cachePath = [self tempFilePathWithURL:url];
    //3.获取文件属性，文件大小
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
    return [fileInfo[NSFileSize] longLongValue];
    
}

+ (void)removeTempWithURL:(NSURL*)url
{
    NSString *tempPath = [self tempFilePathWithURL:url];
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

+ (long long)tempFreeDiskSpace
{
    NSDictionary *tempInfo = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [tempInfo[NSFileSystemFreeSize] longLongValue];
}

+ (void)moveFileToCacheWithURL:(NSURL*)url
{
    if(![self tempFileExitWithURL:url]) return;
    NSString *tempPath = [self tempFilePathWithURL:url];
    NSString *cachePath = [self cacheFilePathWithURL:url];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] moveItemAtPath:tempPath toPath:cachePath error:nil];
    });
    
}


+ (NSString *)contentTypeWithURL:(NSURL*)url
{
    NSString *cachePath = [self cacheFilePathWithURL:url];
    NSString *fileExtension = cachePath.pathExtension;
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef _Nonnull)(fileExtension) , NULL);
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    return contentType;
}


+ (long long)sandboxFreeSizeFromDisk
{
    //获取磁盘大小、剩余空间
    struct statfs buff;
    unsigned long long freespace = -1;
    if(statfs("/var", &buff) >= 0){
        freespace = (long long)(buff.f_bsize * buff.f_bfree);
    }
    return freespace;
}

+ (void)cleanAllVideoCache
{
    NSString *tempPath = [self getFileFolderTempPath];
    NSString *cachePath = [self getFileFolderCachePath];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    });
}

+ (void)getAllVideoSize:(void(^)(unsigned long long total))compeletedOperation
{
    NSString *tempPath = [self getFileFolderTempPath];
    NSString *cachePath = [self getFileFolderCachePath];
    NSArray  *directoryPathArr = @[tempPath,cachePath];
    [self getSizeWithDirectoryPath:directoryPathArr completion:^(long long totalSize) {
        if(compeletedOperation)
            compeletedOperation(totalSize);
    }];
  
}



#pragma mark- pravite

+(NSString *)getFileFolderCachePath
{
    NSFileManager *manger = [NSFileManager defaultManager];
    
    //创建路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:lzb_saveVideoPath];
    
    //如果文件路径不存在，那么就创建文件夹
    if(![manger fileExistsAtPath:path])
    {
        [manger createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

+(NSString *)getFileFolderTempPath
{
    NSFileManager *manger = [NSFileManager defaultManager];
    
    //创建路径
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:lzb_tempVideoPath];
    
    //如果文件路径不存在，那么就创建文件夹
    if(![manger fileExistsAtPath:path])
    {
        [manger createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

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
