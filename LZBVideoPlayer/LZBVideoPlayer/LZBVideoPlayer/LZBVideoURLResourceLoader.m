//
//  LZBVideoURLResourceLoader.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoURLResourceLoader.h"
#import "LZBVideoCachePathTool.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface LZBVideoURLResourceLoader()<LZBVideoDownLoadMangerDelegate>


/**
 下载器
 */
@property (nonatomic, strong) LZBVideoDownLoadManger *downLoadManger;

/**
 请求队列数据
 */
@property (nonatomic, strong) NSMutableArray *appendingRequests;

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

#pragma mark - AVAssetResourceLoaderDelegate

/**
    必须返回Yes，如果返回NO，则resourceLoader将会加载出现故障的数据
 *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理
 *  @param resourceLoader 资源管理器
 *  @param loadingRequest 每一小块数据的请求
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if(resourceLoader && loadingRequest)
    {
        [self.appendingRequests addObject:loadingRequest];
        //处理请求
        [self handleLoadingRequest:loadingRequest];
        
    }
    return YES;
}
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.appendingRequests removeObject:loadingRequest];
}


#pragma mark - pravite
//处理加载请求
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *interuputURL = loadingRequest.request.URL;
    NSRange range = NSMakeRange((NSUInteger)loadingRequest.dataRequest.currentOffset, NSUIntegerMax);
    if(self.downLoadManger == nil)
    {
        self.downLoadManger = [[LZBVideoDownLoadManger alloc]init];
        self.downLoadManger.downloadDelegate = self;
        self.downLoadManger.scheme = self.scheme;
        
        //从头开始加载
        [self.downLoadManger setUrl:interuputURL offset:0];
    }
    else
    {
       if(self.downLoadManger.downLoadingOffset > 0)
       {
           [self handlePendingRequests];
       }
        // 如果新的rang的起始位置比当前缓存的位置还大300k，则重新按照range请求数据
        if (self.downLoadManger.offset + self.downLoadManger.downLoadingOffset + 1024 * 300 < range.location ||
            // 如果往回拖也重新请求
            range.location < self.downLoadManger.offset) {
            [self.downLoadManger setUrl:interuputURL offset:range.location];
        }
    }
    
}

- (void)handlePendingRequests
{
   NSMutableArray *requestsCompleted = [NSMutableArray array];  //请求完成的数组
     //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组,
    for (AVAssetResourceLoadingRequest *request in self.appendingRequests)
    {
        //1.遍历所有的请求, 为每个请求加上请求的数据长度和文件类型等信息
        [self processRequestFillInfomation:request.contentInformationRequest];
        
        //2.判断此次请求的数据是否处理完全,判断当前下载完的数据长度中有没有要请求的数据, 如果有,就把这段数据取出来,并且把这段数据填充给请求, 然后关闭这个请求
        BOOL isDidDataCompletely = [self isCompeletionWithDataForRequest:request.dataRequest];
        //如果是完整的数据，那么把请求增加到完成数组里面
        if(isDidDataCompletely)
        {
            [requestsCompleted addObject:request];
            [request finishLoading];
        }
    }
    
    //移除已经完成的请求
    [self.appendingRequests removeObjectsInArray:[requestsCompleted copy]];
}

//为每个请求增加请求信息
- (void)processRequestFillInfomation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *minetype = self.downLoadManger.mimeType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(minetype), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.downLoadManger.fileLength;
}

//判断请求是否加载完成
- (BOOL)isCompeletionWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    if(dataRequest.currentOffset != 0)
        startOffset = dataRequest.currentOffset;
    if((self.downLoadManger.offset + self.downLoadManger.downLoadingOffset) < startOffset)
        return NO;
    if(startOffset < self.downLoadManger.offset)
        return NO;
    
    NSData *fileData = [NSData dataWithContentsOfFile:self.videoPath options:NSDataReadingMappedIfSafe error:nil];
    NSInteger unreadBytes = self.downLoadManger.downLoadingOffset - self.downLoadManger.offset - (NSInteger)startOffset;
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    [dataRequest respondWithData:[fileData subdataWithRange:NSMakeRange((NSUInteger)startOffset- self.downLoadManger.offset, (NSUInteger)numberOfBytesToRespondWith)]];
    
    long long endOffset = dataRequest.requestedOffset + dataRequest.requestedLength;
    BOOL didRespondFully = (self.downLoadManger.offset + self.downLoadManger.downLoadingOffset) >= endOffset;
    
    return didRespondFully;

}



- (NSMutableArray *)appendingRequests
{
  if(_appendingRequests == nil)
  {
      _appendingRequests = [NSMutableArray array];
  }
    return _appendingRequests;
}
@end
