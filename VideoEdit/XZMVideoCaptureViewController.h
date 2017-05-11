//
//  XZMVideoCaptureViewController.h
//  VideoEdit
//
//  Created by CHT-Technology on 2017/3/31.
//  Copyright © 2017年 CHT-Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface XZMVideoCaptureViewController : UIViewController

- (instancetype)initWithOriginalVideoUrl:(NSURL *)originalVideoUrl;

@property (nonatomic,copy)void(^ completeBlock)(NSURL *captureVideoPath);

@end
