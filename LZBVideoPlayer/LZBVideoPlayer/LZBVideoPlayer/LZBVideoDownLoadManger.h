//
//  LZBVideoDownLoadManger.h
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/6.
//  Copyright © 2017年 Apple. All rights reserved.
//

/*
 * 这个类的功能是从网络请求数据，并把数据保存到本地的一个临时文件.
 * 当网络请求结束或取消的时候，如果数据完整，则把数据缓存到指定的路径，不完整就删除
 */
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class LZBVideoDownLoadManger;

@protocol LZBVideoDownLoadMangerDelegate <NSObject>


/**
  开始下载数据，传出长度和类型
 @param manger 下载对象
 @param videoLength 长度
 @param mimeType 类型
 */
- (void)manger:(LZBVideoDownLoadManger *)manger startDidReceiveVideoLength:(NSUInteger)videoLength mimeType:(NSString *)mimeType;


/**
 下载过程，传递获取到的数据和下载的偏移量以及临时文件存储路径

 @param manager 下载对象
 @param data 获取的到额数据
 @param offset 下载的偏移量
 @param tempFilePath 临时文件存储路径
 */
-(void)manager:(LZBVideoDownLoadManger *)manager downingDidReceiveData:(NSData *)data downloadOffset:(NSInteger)offset tempFilePath:(NSString *)tempFilePath;


/**
 下载完成，传输保存的路径

 @param manager 下载对象
 @param saveFilePath 保存文件存储路径
 */
- (void)manager:(LZBVideoDownLoadManger *)manager didSuccessLoadingWithFileSavePath:(NSString *)saveFilePath;

/**
 下载失败，传输错误信息
 
 @param manager 下载对象
 @param error 传输错误信息
 */
- (void)manager:(LZBVideoDownLoadManger *)manager didFailLoadingWithError:(NSError *)error;
@end

@interface LZBVideoDownLoadManger : NSObject

/**
  代理监听下载状态
 */
@property (nonatomic, weak) id <LZBVideoDownLoadMangerDelegate> downloadDelegate;
/*
 * 视频路径的 scheme，设置scheme
 */
@property (nonatomic, strong) NSString *scheme;
/**
 * 查询是否已经下载完成
 */
@property (nonatomic, assign, readonly) BOOL isFinishLoad;
/**
 * 要下载的文件的URL
 */
@property (nonatomic, strong, readonly) NSURL *url;
/**
 * 文件总长度
 */
@property (nonatomic, assign, readonly) NSUInteger fileLength;
/**
 * 开始下载位置的偏移量
 */
@property (nonatomic, assign, readonly) NSUInteger offset;
/**
 * 已经下载文件的位置
 */
@property (nonatomic, assign, readonly) NSUInteger downLoadedOffset;
/**
 *  下载文件的 mineType 类型
 */
@property (nonatomic, strong, readonly) NSString *mimeType;


#pragma mark- API
/**
 * 传递要下载的文件的URL和下载初始偏移量, 这个方法功能是从网络请求数据，并把数据保存到本地的一个临时文件.
 * 当网络请求结束或取消的时候，如果数据完整，则把数据缓存到指定的路径，不完整就删除
 * @param url 要下载的文件的URL
 * @param offset 下载初始偏移量
 */
- (void)setUrl:(NSURL *)url offset:(long long)offset;

/**
 * 取消当前下载进程
 */
- (void)invalidateAndCancel;

/**
 * 移除数据
 */
- (void)clearData;


@end
