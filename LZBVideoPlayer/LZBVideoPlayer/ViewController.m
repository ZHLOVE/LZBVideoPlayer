//
//  ViewController.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/6/28.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "ViewController.h"
#import "LZBVideoPlayer.h"

@interface ViewController ()
@property (nonatomic, strong) UIView *showView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.showView];
    self.showView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    [[LZBVideoPlayer sharedInstance] playWithURL:[NSURL URLWithString:@"http://www.baidu.com"] showInView:self.showView];
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

@end
