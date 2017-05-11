//
//  XZMVideoCaptureViewController.m
//  VideoEdit
//
//  Created by CHT-Technology on 2017/3/31.
//  Copyright © 2017年 CHT-Technology. All rights reserved.
//

#import "XZMVideoCaptureViewController.h"

#define CaptureLength 10 //截取长度
#define Margin 20 //边缘间距
#define MediaFileName @"SubVideo.mov" //截取视频导入位置
@interface XZMVideoCaptureViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>{
    
    AVPlayer *_player;
    NSURL *_originalVideoUrl;
    NSURL *_captureVideoUrl;
    
    //图片
    UICollectionView *_collectionV;
    NSMutableArray *_picArray;
    long _duration;
}

@end

@implementation XZMVideoCaptureViewController

- (instancetype)initWithOriginalVideoUrl:(NSURL *)originalVideoUrl{
    
    self = [super init];
    if (self) {
        _originalVideoUrl = originalVideoUrl;
    }
    return self;
}

- (void)viewDidLoad {
   
    [self setUpUI];
    
    [self setUpData];
}

#pragma mark -- Privite Methods
- (void)setUpUI{
    
    //创建播放器
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:_originalVideoUrl];
    _player = [[AVPlayer alloc]initWithPlayerItem:item];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];
    layer.frame = CGRectMake(Margin, Margin, CGRectGetMaxX(self.view.bounds) - Margin*2, CGRectGetMaxY(self.view.bounds) - 200);
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:layer];
    [_player play];
    
    
    
    //创建截取视图
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    layout.itemSize = CGSizeMake(25, 50);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionV = [[UICollectionView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(layer.frame) + 20, CGRectGetMaxX(self.view.frame),60) collectionViewLayout:layout];
    _collectionV.decelerationRate = 0;
    _collectionV.dataSource = self;
    _collectionV.delegate = self;
    _collectionV.allowsSelection = NO;
    [_collectionV registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"picCell"];
    [self.view addSubview:_collectionV];
    
    
    //遮罩
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = _collectionV.frame;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    maskLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6].CGColor;
    UIBezierPath *bgPath = [UIBezierPath bezierPathWithRect:_collectionV.bounds];
    UIBezierPath *selectPath = [UIBezierPath bezierPathWithRect:CGRectMake(Margin, 0, 25*CaptureLength, CGRectGetMaxY(_collectionV.bounds))];
    [bgPath appendPath:selectPath];
    maskLayer.path = bgPath.CGPath;
    [self.view.layer addSublayer:maskLayer];
    
    
    UIButton *cancleBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMinX(layer.frame), CGRectGetMaxY(_collectionV.frame) + 30, 60, 40)];
    [cancleBtn setTitle:@"取消" forState:0];
    [cancleBtn addTarget:self action:@selector(cancleBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancleBtn];
    
    
    UIButton *completeBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(layer.frame) - 60, CGRectGetMaxY(_collectionV.frame) + 30, 60, 40)];
    [completeBtn setTitle:@"完成" forState:0];
    [completeBtn addTarget:self action:@selector(completeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:completeBtn];
    

}

- (void)setUpData{
    
    _picArray = [NSMutableArray array];
    [self movieToImage];
}

- (void)videoCaptureWithUrl:(NSURL *)url range:(NSRange)videoRange {
    
    //1.创建视频素材承载对象，获取视频相关信息
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    //2.组建新的素材
    //创建一个新的素材组合对象，可以添加和删除轨道，并可以添加、移除和缩放时间范围
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    //开始位置startTime，timescale：播放速率
    CMTime startTime = CMTimeMakeWithSeconds(videoRange.location, asset.duration.timescale);
    //截取长度videoDuration
    CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, asset.duration.timescale);
    //时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
    //视频轨道
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //在视频轨道插入一个时间段的视频
    [videoCompositionTrack insertTimeRange:videoTimeRange ofTrack:([asset tracksWithMediaType:AVMediaTypeVideo].count>0) ? [asset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil atTime:kCMTimeZero error:nil];
    //音频轨道
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //插入音频数据，否则没有声音
    [audioCompositionTrack insertTimeRange:videoTimeRange ofTrack:([asset tracksWithMediaType:AVMediaTypeAudio].count>0)?[asset tracksWithMediaType:AVMediaTypeAudio].firstObject:nil atTime:kCMTimeZero error:nil];
    
    
    
    // 3.导出新的视频
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    NSString *captureVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:MediaFileName];
    //视频输出路径
    _captureVideoUrl = [NSURL fileURLWithPath:captureVideoPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:captureVideoPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:captureVideoPath error:nil];
    }
    //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
    assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
    assetExportSession.outputURL = _captureVideoUrl;
    //输出文件是否网络优化
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (assetExportSession.error) {
            
            NSLog(@"%@",assetExportSession.error);
        }else{
            
            if (self.completeBlock) {
                self.completeBlock(_captureVideoUrl);
            }
            
            [self cancleBtnClick];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                AVPlayerItem *item = [AVPlayerItem playerItemWithURL:_captureVideoUrl];
//                [_player replaceCurrentItemWithPlayerItem:item];
//                [_player play];
//            });
        }
    }];
}

- (void)movieToImage
{
    
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:_originalVideoUrl options:nil];
    //视频资源截图工具
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    
    _duration = asset.duration.value/asset.duration.timescale;
    NSLog(@"%ld",_duration);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 1; i < _duration+1; i ++ ) {
            
            [generator generateCGImagesAsynchronouslyForTimes:
             [NSArray arrayWithObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(i,NSEC_PER_SEC)]] completionHandler:^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
                 if (result != AVAssetImageGeneratorSucceeded) {       }//没成功
                 
                 UIImage *thumbImg = [UIImage imageWithCGImage:im];
                 [_picArray addObject:thumbImg];
                 
                 if (i == _duration) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [_collectionV reloadData];
                     });
                 }
             }];
        }

    });
    
    
}

- (void)cancleBtnClick{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)completeBtnClick{
    
    [self videoCaptureWithUrl:_originalVideoUrl range:NSMakeRange(_collectionV.contentOffset.x/_collectionV.contentSize.width*CMTimeGetSeconds(_player.currentItem.duration), CaptureLength)];
    
    
}

#pragma mark -- UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return _picArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"picCell" forIndexPath:indexPath];
    
    UIImageView *imageV = [cell.contentView viewWithTag:1000];
    if (!imageV) {
        imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 25, 50)];
        [cell.contentView addSubview:imageV];
        imageV.tag = 1000;
    }
    imageV.image = _picArray[indexPath.row];
    
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [_player pause];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CMTime currentTime = CMTimeMake(scrollView.contentOffset.x/scrollView.contentSize.width*CMTimeGetSeconds(_player.currentItem.duration),1);

    [_player seekToTime:currentTime completionHandler:^(BOOL finished) {
        
//        [_player ]
    }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    [_player play];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if (!decelerate) {
        [_player play];
//        [self videoCaptureWithUrl:_originalVideoUrl range:NSMakeRange(scrollView.contentOffset.x/scrollView.contentSize.width*CMTimeGetSeconds(_player.currentItem.duration), CaptureLength)];
    }
    
}

#pragma mark -- touch
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (_player.rate == 1) {
        [_player pause];
    }else{
        
        [_player play];
    }
}

- (void)dealloc
{
    NSLog(@"%@死了",NSStringFromClass([self class]));
}

@end
