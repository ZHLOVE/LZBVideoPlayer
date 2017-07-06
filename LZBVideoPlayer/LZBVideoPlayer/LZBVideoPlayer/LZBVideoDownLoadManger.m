//
//  LZBVideoDownLoadManger.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoDownLoadManger.h"
#import "LZBVideoCachePathTool.h"

#define TIME_OUT_INTERVAL   10.0  //超时时间

@interface LZBVideoDownLoadManger() <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSString *tempPath;

@property (nonatomic, assign) BOOL isFinishLoad;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) NSUInteger fileLength;
@property (nonatomic, assign) NSUInteger offset;
@property (nonatomic, assign) NSUInteger downLoadedOffset;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, assign) BOOL timeOutOnce;
@end

@implementation LZBVideoDownLoadManger
#pragma mark - API
- (void)setUrl:(NSURL *)url offset:(long long)offset
{
    self.url = url;
    self.offset = offset;
    self.downLoadedOffset = 0;
    self.fileName = [LZBVideoCachePathTool getFileNameWithURL:url];
    [self startLoading];
}

- (void)invalidateAndCancel
{
    [self.session invalidateAndCancel];
}

- (void)clearData
{
    [self invalidateAndCancel];
    //移除文件
    [[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:nil];
}


#pragma mark - NSURLSessionDataDelegate
// 接收到服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
  didReceiveResponse:(NSURLResponse *)response
   completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSLog(@"开始下载");
    self.mimeType = @"video/mp4";
    self.isFinishLoad = NO;
    self.tempPath = [self getTempFileCachePath];
    //1.获取文件总长度,如果响应头里有文件长度数据, 就取这个长度; 如果没有, 就取代理方法返回给我们的长度
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSDictionary *dict = (NSDictionary *)[httpResponse allHeaderFields];
    NSString *content = [dict valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    NSUInteger videoLength;
    if ([length integerValue] == 0) {
        videoLength = (NSUInteger)httpResponse.expectedContentLength;
    } else {
        videoLength = [length integerValue];
    }
    self.fileLength = videoLength;
    
    //2.剩余空间计算
    if(![self checkDiskFreeSize:videoLength])
    {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    //3.如果空间充足,可以继续下载
    if([self.downloadDelegate respondsToSelector:@selector(manger:startDidReceiveVideoLength:mimeType:)])
    {
        [self.downloadDelegate manger:self startDidReceiveVideoLength:self.fileLength mimeType:self.mimeType];
    }
    
    self.outputStream = [[NSOutputStream alloc]initToFileAtPath:self.tempPath append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}
// 接收到服务器返回数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    if(data.length > 0)
    {
        self.downLoadedOffset += data.length;
        [self.outputStream write:data.bytes maxLength:data.length];
        //接受到数据
        if([self.downloadDelegate respondsToSelector:@selector(manager:downingDidReceiveData:downloadOffset:tempFilePath:)])
        {
            [self.downloadDelegate manager:self downingDidReceiveData:data downloadOffset:self.downLoadedOffset tempFilePath:self.tempPath];
        }
    }
}

//请求结束的时候调用，成功和失败都会调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
   if(error == nil){
       [self downloadSuccessWithURLSession:session task:task];
   }
   else{
       [self downloadFailWithURLSession:session task:task error:error];
    }
}

//下载成功
-(void)downloadSuccessWithURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
{
  // 如果下载完成, 就把缓存文件移到保存文件夹
    self.isFinishLoad = YES;
    NSString *saveFilePath = [LZBVideoCachePathTool getFilePathWithSaveCache];
    NSString *saveFullPath = [saveFilePath stringByAppendingPathComponent:self.fileName];
    NSFileManager *fileManger = [NSFileManager defaultManager];
    if([fileManger fileExistsAtPath:self.tempPath])
    {
        //异步把缓存文件移到保存文件夹
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
           [fileManger moveItemAtPath:self.tempPath toPath:saveFullPath error:nil];
            
            //回到主线程调用代理
           if([self.downloadDelegate respondsToSelector:@selector(manager:didSuccessLoadingWithFileSavePath:)]){
                [self.downloadDelegate manager:self didSuccessLoadingWithFileSavePath:saveFullPath];
            }
        });
    }
    
    
    //关闭流
    [self.outputStream close];
    self.outputStream = nil;
}

//下载失败
- (void)downloadFailWithURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task error:(NSError *)error
{
    //网络中断：-1005
    //无网络连接：-1009
    //请求超时：-1001
    //服务器内部错误：-1004
    //找不到服务器：-1003
    
    if (error.code == -1009) {
        NSLog(@"No Connect 无网络连接,请检测连接");
    }
    
    if(error.code == -1001 && !self.timeOutOnce)
    {
        // 网络超时，重连一次
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startLoading];
            self.timeOutOnce = YES;
        });
    }
    
    if([self.downloadDelegate respondsToSelector:@selector(manager:didFailLoadingWithError:)])
    {
        [self.downloadDelegate manager:self didFailLoadingWithError:error];
    }
}


#pragma mark -pravite
//开始加载
- (void)startLoading
{
    //1.NSURLComponents修改scheme
    NSURLComponents *componet = [[NSURLComponents alloc]initWithURL:self.url resolvingAgainstBaseURL:NO];
    componet.scheme = self.scheme.length == 0 ? @"systemNotKnow" : self.scheme;
    
    //2、创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[componet URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIME_OUT_INTERVAL];
    
    //3.修改请求数据的范围
    if(self.offset > 0 && self.fileLength > 0)
    {
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)self.offset, (unsigned long)self.fileLength - 1] forHTTPHeaderField:@"Range"];
    }
    
    //4.重置请求
    if(self.session != nil)
        [self.session invalidateAndCancel];
    
    //5.创建请求会话session
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    //6.创建请求任务
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    
    //7.开始下载
    [dataTask resume];
}

//获取临时缓存路径
- (NSString *)getTempFileCachePath
{
    NSString *tempFilePath = [LZBVideoCachePathTool getFilePathWithTempCache];
    NSString *tempFullPath = [tempFilePath stringByAppendingPathComponent:self.fileName];
    NSFileManager *fileManger = [NSFileManager defaultManager];
    if([fileManger fileExistsAtPath:tempFullPath])
    {
        [fileManger removeItemAtPath:tempFullPath error:nil];
    }
    
    [fileManger createFileAtPath:tempFullPath contents:nil attributes:nil];
    return tempFullPath;
}

- (BOOL)checkDiskFreeSize:(NSUInteger)length
{
    return YES;
}
@end
