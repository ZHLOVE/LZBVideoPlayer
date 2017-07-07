//
//  LZBPlayerBottomControlView.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/7.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBPlayerBottomControlView.h"


@interface LZBPlayerBottomControlView()

@end

@implementation LZBPlayerBottomControlView
- (instancetype)initWithFrame:(CGRect)frame
{
   if(self = [super initWithFrame:frame])
   {
       [self addSubview:self.currentTimeLabel];
       [self addSubview:self.totalTimeLabel];
       [self addSubview:self.slider];
       [self addSubview:self.progressView];
       [self addSubview:self.playPasueButton];
       [self addSubview:self.lastButton];
       [self addSubview:self.nextButton];
       [self addSubview:self.fullScreenButton];
   }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize imageSize = [self imageWithNamed:@"Expression_81"].size;
    self.playPasueButton.frame = CGRectMake((self.bounds.size.width - imageSize.width)*0.5 , self.bounds.size.height -imageSize.height , imageSize.width, imageSize.height);
    self.lastButton.bounds = self.playPasueButton.bounds;
    self.lastButton.center = CGPointMake(self.playPasueButton.center.x - 30 , self.playPasueButton.center.y);
    
    self.nextButton.bounds = self.playPasueButton.bounds;
    self.nextButton.center = CGPointMake(self.playPasueButton.center.x + 30 , self.playPasueButton.center.y);
    
    self.fullScreenButton.bounds = self.playPasueButton.bounds;
    self.fullScreenButton.center = CGPointMake(self.bounds.size.width - imageSize.width, self.playPasueButton.center.y);
    
    self.currentTimeLabel.frame = CGRectMake(20, 20, 50, 40);
    self.totalTimeLabel.frame = CGRectMake(self.bounds.size.width -20, 20, 50, 40);
    self.slider.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame) + 10, 0, self.bounds.size.width - 60, 30);
    self.progressView.frame= CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame) + 10, 0, self.bounds.size.width - 60, 10);
    
}


#pragma mark -lazy
+ (CGFloat)getPlayerBottomHeight
{
    return  60;
}
- (UILabel *)currentTimeLabel
{
  if(_currentTimeLabel == nil)
  {
      _currentTimeLabel = [UILabel new];
      _currentTimeLabel.textColor = [UIColor whiteColor];
      _currentTimeLabel.font = [UIFont systemFontOfSize:10.0];
      _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
  }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel
{
    if(_totalTimeLabel == nil)
    {
        _totalTimeLabel = [UILabel new];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:10.0];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIProgressView *)progressView
{
  if(_progressView == nil)
  {
      _progressView = [UIProgressView new];
      _progressView.progressTintColor = [UIColor redColor];  //填充部分颜色
      _progressView.trackTintColor = [UIColor lightGrayColor];   // 未填充部分颜色
      _progressView.layer.cornerRadius = 1.5;
      _progressView.layer.masksToBounds = YES;
      CGAffineTransform transform = CGAffineTransformMakeScale(1.0, 1.5);
      _progressView.transform = transform;
  }
    return _progressView;
}

- (UISlider *)slider
{
  if(_slider == nil)
  {
      _slider = [UISlider new];
      _slider.minimumTrackTintColor = [UIColor clearColor];
      _slider.maximumTrackTintColor = [UIColor clearColor];
  }
    return _slider;
}

- (UIButton *)playPasueButton
{
  if(_playPasueButton == nil)
  {
      _playPasueButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [_playPasueButton setImage:[self imageWithNamed:@"Expression_86"] forState:UIControlStateNormal];
  }
    return _playPasueButton;
}

- (UIButton *)lastButton
{
  if(_lastButton == nil)
  {
    _lastButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_lastButton setImage:[self imageWithNamed:@"Expression_80"] forState:UIControlStateNormal];
  }
    return _lastButton;
}
- (UIButton *)nextButton
{
    if(_nextButton == nil)
    {
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_nextButton setImage:[self imageWithNamed:@"Expression_81"] forState:UIControlStateNormal];
    }
    return _nextButton;
}

- (UIButton *)fullScreenButton
{
    if(_fullScreenButton == nil)
    {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [_fullScreenButton setImage:[self imageWithNamed:@"Expression_79"] forState:UIControlStateNormal];
    }
    return _fullScreenButton;
}

- (UIImage *)imageWithNamed:(NSString *)imageName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PlayerImage" ofType:@"bundle"];
    return [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", imageName]]];
}
@end
