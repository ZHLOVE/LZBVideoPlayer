//
//  LZBVideoURLResourceLoader.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoURLResourceLoader.h"
#import "LZBVideoFileManger.h"

@interface LZBVideoURLResourceLoader()<LZBVideoDownLoadMangerDelegate>
/**
 下载器
 */
@property (nonatomic, strong) LZBVideoDownLoadManger *downLoadManger;

/**
 请求队列数据
 */
@property (nonatomic, strong) NSMutableArray *downLoadedDataRequests;

/**
  soure URL
 */
@property(nonatomic, strong)  NSURL *inputURL;

@end

@implementation LZBVideoURLResourceLoader

#pragma mark - AVAssetResourceLoaderDelegate

/**
    必须返回Yes，如果返回NO，则resourceLoader将会加载出现故障的数据
 *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理
 *  @param resourceLoader 资源管理器
 *  @param loadingRequest 每一小块数据的请求
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    
    NSLog(@"开始资源请求");
    //1.判断请求资源是否已经下载，如果已经下载，就直接把数据响应给外界并 retern
    if([LZBVideoFileManger cacheFileExitWithURL:self.inputURL])
    {
        [self hanleLocationDidLoadedDataRequest:loadingRequest];
        return YES;
    }
    
    //获取请求起始位置
    long long requireStartOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    if(requireStartOffset != currentOffset)
        requireStartOffset = currentOffset;
    
    [self.downLoadedDataRequests addObject:loadingRequest];
    
    //2.判断是否已经有部分数据，如果没有，就重头开始下载并return
    if(self.downLoadManger.downLoadSize == 0)
    {
        [self.downLoadManger downLoaderWithURL:self.inputURL offset:requireStartOffset];
        return YES;
    }
    
    //3.判断请求的区间数据是否在已经下载的区间，如果不在，就重新下载
    //3.1 请求开始点 < 已经下载资源的开始点
    //3.2 请求开始点 > 已经下载资源的开始点 + 长度 + 多一段长度（自定义100)
    if(requireStartOffset < self.downLoadManger.startOffset || requireStartOffset > self.downLoadManger.startOffset + self.downLoadManger.downLoadSize + 100)
    {
        [self.downLoadManger invalidateAndClean];
        [self.downLoadManger downLoaderWithURL:self.inputURL offset:requireStartOffset];
        return YES;
    }
    //4.响应部分数据给外界，并继续处理请求
    [self hanleAllLoadingRequests];
    return YES;
}
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.downLoadedDataRequests removeObject:loadingRequest];
}


#pragma mark -  LZBVideoDownLoadMangerDelegate
//正在下载中
- (void)manager:(LZBVideoDownLoadManger *)manager downingDidReceiveData:(NSData *)data downloadOffset:(NSInteger)offset tempFilePath:(NSString *)tempFilePath
{
    [self hanleAllLoadingRequests];
}
//下载成功
- (void)manager:(LZBVideoDownLoadManger *)manager didSuccessLoadingWithFileSavePath:(NSString *)saveFilePath
{
    if([self.delegate respondsToSelector:@selector(didFinishSucessLoadedWithManger:saveVideoPath:)])
    {
        [self.delegate didFinishSucessLoadedWithManger:manager saveVideoPath:saveFilePath];
    }
}
//下载失败
- (void)manager:(LZBVideoDownLoadManger *)manager didFailLoadingWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(didFailLoadedWithManger:withError:)])
    {
        [self.delegate didFailLoadedWithManger:manager withError:error];
    }
}

#pragma mark - pravite
//处理加载请求
- (void)hanleAllLoadingRequests
{
    NSMutableArray *deleteRequests = [NSMutableArray array];  //请求完成的数组
    //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组,
    for (AVAssetResourceLoadingRequest *request in self.downLoadedDataRequests)
    {
        //1.遍历所有的请求, 为每个请求加上请求的数据长度和文件类型等信息
        [self processRequestFillInfomation:request.contentInformationRequest];
        
        //2.判断此次请求的数据是否处理完全,判断当前下载完的数据长度中有没有要请求的数据, 如果有,就把这段数据取出来,并且把这段数据填充给请求, 然后关闭这个请求
        BOOL isDidDataCompletely = [self isCompeletionWithDataForRequest:request.dataRequest];
        //如果是完整的数据，那么把请求增加到完成数组里面
        if(isDidDataCompletely)
        {
            [deleteRequests addObject:request];
            [request finishLoading];
            NSLog(@"---下载好的资源给外界");
        }
    }
    
    //移除已经完成的请求
    [self.downLoadedDataRequests removeObjectsInArray:[deleteRequests copy]];
}





//为每个请求增加请求信息
- (void)processRequestFillInfomation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *minetype = self.downLoadManger.mimeType;
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = minetype;
    contentInformationRequest.contentLength = self.downLoadManger.totalSize;
}

//判断请求是否加载完成
- (BOOL)isCompeletionWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long requestedOffset = dataRequest.requestedOffset;
    long long currentOffset = dataRequest.currentOffset;
    long long requestedLength = dataRequest.requestedLength;
    if(requestedOffset != currentOffset)
        requestedOffset = currentOffset;
//    
    NSData *data = [NSData dataWithContentsOfFile:[LZBVideoFileManger tempFilePathWithURL:self.inputURL] options:NSDataReadingMappedIfSafe error:nil];
    if(data.length == 0)
    {
        data = [NSData dataWithContentsOfFile:[LZBVideoFileManger cacheFilePathWithURL:self.inputURL] options:NSDataReadingMappedIfSafe error:nil];
    }

    NSUInteger responseOffset = requestedOffset - self.downLoadManger.startOffset;
    NSUInteger unreadBytes = self.downLoadManger.downLoadSize - requestedOffset - self.downLoadManger.startOffset;
//    NSUInteger unreadBytes = self.downLoadManger.startOffset + self.downLoadManger.downLoadSize - requestedOffset;
    NSUInteger responseLength = MIN(unreadBytes, requestedLength);
  
    NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
    [dataRequest respondWithData:subData];
    
//    BOOL compeletion = requestedLength == responseLength;
//    return compeletion;
    
//    // This is the total data we have from startOffset to whatever has been downloaded so far
//    NSUInteger unreadBytes = self.downLoadManger.downLoadSize - ((NSInteger)requestedOffset - self.downLoadManger.startOffset);
//    
//    // Respond with whatever is available if we can't satisfy the request fully yet
//    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
//    
//    
//    [dataRequest respondWithData:[data subdataWithRange:NSMakeRange((NSUInteger)requestedOffset- self.downLoadManger.startOffset, (NSUInteger)numberOfBytesToRespondWith)]];
    
    
    
    long long endOffset = requestedOffset + dataRequest.requestedLength;
    BOOL didRespondFully = (self.downLoadManger.startOffset + self.downLoadManger.downLoadSize) >= endOffset;
    
    return didRespondFully;
    

}

//处理本地已经下载好的数据，响应给外界
- (void)hanleLocationDidLoadedDataRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    //1.填充请求信息
    loadingRequest.contentInformationRequest.contentType = [LZBVideoFileManger contentTypeWithURL:self.inputURL];
    loadingRequest.contentInformationRequest.contentLength = [LZBVideoFileManger cacheFileSizeWithURL:self.inputURL];
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    //2.响应数据到外界
    NSData *data = [NSData dataWithContentsOfFile:[LZBVideoFileManger cacheFilePathWithURL:self.inputURL] options:NSDataReadingMappedIfSafe error:nil];
    
    long long responseOffset = loadingRequest.dataRequest.requestedOffset;
    long long responseLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
    [loadingRequest.dataRequest respondWithData:subData];
    
    //3.结束响应
    [loadingRequest finishLoading];
    
}



#pragma mark- API

- (NSURL *)getVideoResourceLoaderSchemeWithURL:(NSURL *)inputURL;
{
    
    // NSURLComponents用来替代NSMutableURL，可以readwrite修改URL
    // AVAssetResourceLoader通过你提供的委托对象去调节AVURLAsset所需要的加载资源。
    // 而很重要的一点是，AVAssetResourceLoader仅在AVURLAsset不知道如何去加载这个URL资源时才会被调用
    // 就是说你提供的委托对象在AVURLAsset不知道如何加载资源时才会得到调用。
    // 所以我们又要通过一些方法来曲线解决这个问题，把我们目标视频URL地址的scheme替换为系统不能识别的scheme
    if(inputURL.absoluteString.length == 0) return nil;
    NSURLComponents *component = [NSURLComponents componentsWithURL:inputURL resolvingAgainstBaseURL:NO];
    self.inputURL = inputURL;
    component.scheme = @"lzbsystemNotKnow";
    return [component URL];
}

- (void)invalidDownloader
{
    [self.downLoadManger invalidateAndCancel];
    self.downLoadManger = nil;
}


#pragma mark- lazy

- (NSMutableArray *)downLoadedDataRequests
{
  if(_downLoadedDataRequests == nil)
  {
      _downLoadedDataRequests = [NSMutableArray array];
  }
    return _downLoadedDataRequests;
}

- (LZBVideoDownLoadManger *)downLoadManger
{
  if(_downLoadManger == nil)
  {
      _downLoadManger = [[LZBVideoDownLoadManger alloc]init];
      _downLoadManger.downloadDelegate = self;
  }
    return _downLoadManger;
}
@end
