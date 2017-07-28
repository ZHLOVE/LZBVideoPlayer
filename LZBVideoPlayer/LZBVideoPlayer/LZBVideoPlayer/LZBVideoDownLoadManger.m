//
//  LZBVideoDownLoadManger.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoDownLoadManger.h"
#import "LZBVideoFileManger.h"

#define TIME_OUT_INTERVAL   10.0  //超时时间

@interface LZBVideoDownLoadManger() <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) BOOL timeOutOnce;
@end

@implementation LZBVideoDownLoadManger
#pragma mark - API
- (void)downLoaderWithURL:(NSURL *)url offset:(long long)offset;
{
    self.url = url;
    self.startOffset = offset;
    [self startLoading];
}

- (void)invalidateAndCancel
{
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)invalidateAndClean
{
    [self invalidateAndCancel];
    self.downLoadSize = 0;
    //移除文件
    [LZBVideoFileManger removeTempWithURL:self.url];
}

//开始加载
- (void)startLoading
{
    //1.如果存在下载任务，那么就清除
    if(self.session != nil)
    {
        [self invalidateAndClean];
    }
    //2、创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIME_OUT_INTERVAL];
    
    //3.修改请求数据的范围
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", self.startOffset] forHTTPHeaderField:@"Range"];
    //4.创建请求任务
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    
    //5.开始下载
    [dataTask resume];
}


#pragma mark - NSURLSessionDataDelegate
// 接收到服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
  didReceiveResponse:(NSHTTPURLResponse *)response
   completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSLog(@"开始下载");
    //1.获得区间文件的大小长度
    NSDictionary *responseDict = [response allHeaderFields];
    self.totalSize = [responseDict[@"Content-Length"] longLongValue];
    NSString *contentRangeString = [responseDict valueForKey:@"Content-Range"];
    if(contentRangeString.length != 0)
        self.totalSize = [[contentRangeString componentsSeparatedByString:@"/"].lastObject longLongValue];;
    
    self.mimeType = response.MIMEType;
    
    //2.剩余空间计算
    if([LZBVideoFileManger tempFreeDiskSpace] < self.totalSize)
    {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    //3.如果空间充足,可以继续下载
    if([self.downloadDelegate respondsToSelector:@selector(manger:startDidReceiveVideoLength:mimeType:)])
    {
        [self.downloadDelegate manger:self startDidReceiveVideoLength:self.totalSize mimeType:self.mimeType];
    }
    
    self.outputStream = [[NSOutputStream alloc]initToFileAtPath:[LZBVideoFileManger tempFilePathWithURL:self.url] append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}
// 接收到服务器返回数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
   
    self.downLoadSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    //接受到数据
    if([self.downloadDelegate respondsToSelector:@selector(manager:downingDidReceiveData:downloadOffset:tempFilePath:)])
    {
        [self.downloadDelegate manager:self downingDidReceiveData:data downloadOffset:self.downLoadSize tempFilePath:[LZBVideoFileManger tempFilePathWithURL:self.url]];
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

    //1.判断文件是否完整，如果完整，就从temp - 移动到cache
    if(self.totalSize == [LZBVideoFileManger tempFileSizeWithURL:self.url])
    {
        [LZBVideoFileManger moveFileToCacheWithURL:self.url];
    }
    //代理回调数据
    if([self.downloadDelegate respondsToSelector:@selector(manager:didSuccessLoadingWithFileSavePath:)])
    {
        [self.downloadDelegate manager:self didSuccessLoadingWithFileSavePath:[LZBVideoFileManger cacheFilePathWithURL:self.url]];
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
    if(error.code == -999)
    {
        NSLog(@"----请求取消");
        return;
    }
    
    if(error.code == -1001 && !self.timeOutOnce)
    {
        // 网络超时，重连一次
        __weak typeof(self) weakSelf = self;
        NSLog(@"下载失败-----%@",error);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.timeOutOnce = YES;
            [weakSelf startLoading];
        });
        return;
    }
    
    NSString *localMessage = error.userInfo[@"NSLocalizedDescription"];
    NSError *failError = [NSError errorWithDomain:localMessage code:error.code userInfo:error.userInfo];
    NSLog(@"下载失败-----%@",failError);
    
    if([self.downloadDelegate respondsToSelector:@selector(manager:didFailLoadingWithError:)])
    {
        [self.downloadDelegate manager:self didFailLoadingWithError:failError];
    }
}

#pragma mark - lazy

- (void)setMimeType:(NSString *)mimeType
{
    _mimeType = mimeType;
}
- (void)setStartOffset:(long long)startOffset
{
    _startOffset = startOffset;
}
- (void)setDownLoadSize:(long long)downLoadSize
{
    _downLoadSize = downLoadSize;
}

- (void)setTotalSize:(long long)totalSize
{
    _totalSize = totalSize;
}

- (NSURLSession *)session
{
  if(_session == nil)
  {
      _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
  }
    return _session;
}
@end
