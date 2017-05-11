//
//  ViewController.m
//  VideoEdit
//
//  Created by CHT-Technology on 2017/3/30.
//  Copyright © 2017年 CHT-Technology. All rights reserved.
//

#import "ViewController.h"
#import "XZMVideoCaptureViewController.h"

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    
    AVPlayer *_player;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _player = [[AVPlayer alloc]init];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];
    layer.frame = CGRectMake(20, 20, CGRectGetMaxX(self.view.bounds) - 40, 200);
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:layer];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 50)];
    btn.backgroundColor = [UIColor grayColor];
    [btn setTitle:@"选取" forState:0];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.center = self.view.center;
    
}

- (void)btnClick{
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
//    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.mediaTypes =  @[(NSString *)kUTTypeMovie];
    [self presentViewController:imagePickerController animated:YES completion:^{
        
    }];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:^{
        
        XZMVideoCaptureViewController *captureVC = [[XZMVideoCaptureViewController alloc]initWithOriginalVideoUrl:videoUrl];
        [self presentViewController:captureVC animated:NO completion:nil];
        
        captureVC.completeBlock = ^(NSURL *captureUrl){
            AVPlayerItem *item = [[AVPlayerItem alloc]initWithURL:captureUrl];
            [_player replaceCurrentItemWithPlayerItem:item];
            [_player play];
        };
    }];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    
    [_player seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
        
        [_player play];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
