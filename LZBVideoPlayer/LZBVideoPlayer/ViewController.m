//
//  ViewController.m
//  LZBVideoPlayer
//
//  Created by zibin on 2016/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "ViewController.h"
#import "LZBVideoPlayerView.h"

@interface ViewController ()

@property (nonatomic, strong) UIView *showView;

@property (nonatomic, strong) LZBVideoPlayerView *playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.playerView];
    self.playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    [self.playerView playWithURL:[NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"] isSupportCache:YES];
}

- (UIView *)showView
{
  if(_showView == nil)
  {
      _showView = [UIView new];
      _showView.backgroundColor = [UIColor greenColor];
  }
    return _showView;
}


- (LZBVideoPlayerView *)playerView
{
  if(_playerView == nil)
  {
      _playerView = [[LZBVideoPlayerView alloc]init];
  }
    return _playerView;
}

@end
