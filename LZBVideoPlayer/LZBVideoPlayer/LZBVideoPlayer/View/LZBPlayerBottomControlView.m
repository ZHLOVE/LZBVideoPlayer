//
//  LZBPlayerBottomControlView.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/7/7.
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
       [self addSubview:self.progressView];
       [self addSubview:self.slider];
       [self addSubview:self.playPasueButton];
       [self addSubview:self.lastButton];
       [self addSubview:self.nextButton];
       [self addSubview:self.fullScreenButton];
       self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
   }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize imageSize = CGSizeMake(35, 35);
    self.playPasueButton.frame = CGRectMake((self.bounds.size.width - imageSize.width)*0.5 , self.bounds.size.height -imageSize.height , imageSize.width, imageSize.height);
    self.lastButton.bounds = self.playPasueButton.bounds;
    self.lastButton.center = CGPointMake(self.playPasueButton.center.x - 50 , self.playPasueButton.center.y);
    
    self.nextButton.bounds = self.playPasueButton.bounds;
    self.nextButton.center = CGPointMake(self.playPasueButton.center.x + 50 , self.playPasueButton.center.y);
    
    self.fullScreenButton.bounds = self.playPasueButton.bounds;
    self.fullScreenButton.center = CGPointMake(self.bounds.size.width - imageSize.width, self.playPasueButton.center.y);
    
    self.currentTimeLabel.frame = CGRectMake(10, 0, 40, 30);
    self.totalTimeLabel.frame = CGRectMake(self.bounds.size.width -10 - 30, 0, 40, 30);
    self.slider.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame) + 10, 0, self.bounds.size.width - 2 *CGRectGetMaxX(self.currentTimeLabel.frame) -20, 30);
    self.progressView.frame= CGRectMake(self.slider.frame.origin.x, self.slider.bounds.size.height *0.5, self.slider.bounds.size.width, 10);
    
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
      _currentTimeLabel.text = @"00:00";
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
        _totalTimeLabel.text = @"30:40";
    }
    return _totalTimeLabel;
}

- (UIProgressView *)progressView
{
  if(_progressView == nil)
  {
      _progressView = [UIProgressView new];
      _progressView.progressTintColor = [UIColor greenColor];  //填充部分颜色
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
      UIImage *pauseButtonImage = [[self imageWithNamed:@"lzb_pause@3x"]   stretchableImageWithLeftCapWidth:1  topCapHeight:1];
      UIImage *playButtonImage = [[self imageWithNamed:@"lzb_play@3x"]   stretchableImageWithLeftCapWidth:1  topCapHeight:1];
      [_playPasueButton setImage: pauseButtonImage forState:UIControlStateNormal];
      [_playPasueButton setImage: playButtonImage forState:UIControlStateSelected];
  }
    return _playPasueButton;
}

- (UIButton *)lastButton
{
  if(_lastButton == nil)
  {
    _lastButton = [UIButton buttonWithType:UIButtonTypeCustom];
     UIImage *lastButtonImage = [[self imageWithNamed:@"lzb_last@3x"]   stretchableImageWithLeftCapWidth:10  topCapHeight:10];
      [_lastButton setImage:lastButtonImage forState:UIControlStateNormal];
  }
    return _lastButton;
}
- (UIButton *)nextButton
{
    if(_nextButton == nil)
    {
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *nextButtonImage = [[self imageWithNamed:@"lzb_next@3x"]   stretchableImageWithLeftCapWidth:1  topCapHeight:1];
        [_nextButton setImage:nextButtonImage forState:UIControlStateNormal];
    }
    return _nextButton;
}

- (UIButton *)fullScreenButton
{
    if(_fullScreenButton == nil)
    {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
      [_fullScreenButton setImage:[self imageWithNamed:@"lzb_next@3x"] forState:UIControlStateNormal];
    }
    return _fullScreenButton;
}

- (UIImage *)imageWithNamed:(NSString *)imageName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PlayerImage" ofType:@"bundle"];
    UIImage *image = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", imageName]]];
    return image;
}
@end
