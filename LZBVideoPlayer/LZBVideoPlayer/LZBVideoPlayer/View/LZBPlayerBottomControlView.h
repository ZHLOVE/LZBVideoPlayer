//
//  LZBPlayerBottomControlView.h
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/7.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LZBPlayerBottomControlView : UIView

/**
    当前时间Label
 */
@property (nonatomic, strong)  UILabel *currentTimeLabel;
/**
    总时间Label
 */
@property (nonatomic, strong)  UILabel *totalTimeLabel;

/**
  进度条
 */
@property (nonatomic, strong) UIProgressView *progressView;

/**
  滑块
 */
@property (nonatomic, strong) UISlider *slider;

/**
  播放暂停按钮
 */
@property (nonatomic, strong) UIButton *playPasueButton;

/**
 上一步按钮
 */
@property (nonatomic, strong) UIButton *lastButton;

/**
 下一步按钮
 */
@property (nonatomic, strong) UIButton *nextButton;

/**
  全屏按钮
 */
@property (nonatomic, strong) UIButton *fullScreenButton;

//设底部的高度
+ (CGFloat)getPlayerBottomHeight;
@end
