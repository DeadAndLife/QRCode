//
//  QRCodeVC.m
//  QRCode
//
//  Created by qingyun on 16/7/2.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import "QRCodeVC.h"
#import <AVFoundation/AVFoundation.h>

@interface QRCodeVC ()<AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIImageView *boardView;
@property (nonatomic, strong) UIImageView *imageView;//动画
@property (nonatomic, strong) NSTimer *timer;


@property (nonatomic, strong)AVCaptureDevice *device;//设备
@property (nonatomic, strong)AVCaptureDeviceInput *input;//从设备输入到应用
@property (nonatomic, strong)AVCaptureSession *session;//中间会话,处理内容
@property (nonatomic, strong)AVCaptureMetadataOutput *output;//输出结果

@end

@implementation QRCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //设置扫描区域的边框
    UIImage *image = [UIImage imageNamed:@"qrcode_border"];
    //设置图片的拉伸区域
    UIImage *resizableImage = [image resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 26, 26)];
    self.boardView.image = resizableImage;
    
    //添加动画View
    self.imageView = [[UIImageView alloc] initWithFrame:self.boardView.bounds];
    self.imageView.image = [UIImage imageNamed:@"qrcode_scanline_qrcode"];
    [self.boardView addSubview:self.imageView];
    self.boardView.clipsToBounds = YES;//减掉超出区域
    
    
    //启动一个timer, 刷新UI
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(changeImageView) userInfo:nil repeats:YES];
    
    
    
}


-(void)changeImageView{
    self.imageView.frame = CGRectOffset(self.imageView.frame, 0, 5);
    if (self.imageView.frame.origin.y >= self.boardView.frame.size.height - 30) {
        self.imageView.frame = CGRectMake(0, -self.boardView.frame.size.height, self.boardView.frame.size.height, self.boardView.frame.size.height);
    }
}

-(void)viewDidLayoutSubviews{
    //更新完成子视图
    //使用UIview动画,实现动画
    CGFloat height = self.boardView.frame.size.height;//宽和高相等
    self.imageView.frame = CGRectMake(0, - height, height, height);
//    [UIView animateWithDuration:3.f
//                          delay:0
//                        options:UIViewAnimationOptionRepeat
//                     animations:^{
//                         self.imageView.frame = CGRectMake(0, height, height, height);
//                     } completion:^(BOOL finished) {
//                         
//                     }];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self statartRead];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopRead];
}

//开始二维码扫描
-(void)statartRead{
    //1.device
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];//选择视频设备,扫描画面
    //2.input
    NSError *error;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    
    //3.初始化sessionn
    self.session = [[AVCaptureSession alloc] init];
    
    [self.session addInput:self.input];
    
    //4.初始化output
    self.output = [[AVCaptureMetadataOutput alloc] init];
    
    //初始化一个队列
    dispatch_queue_t queue = dispatch_queue_create("myqueue", NULL);
    //设置output的delegate
    [self.output setMetadataObjectsDelegate:self queue:queue];
    
    [self.session addOutput:self.output];
    
    //配置output,设置要输出的元数据的类型,在output添加到session之后配置才有效
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode , AVMetadataObjectTypeEAN13Code]];
    
    //设置预览效果,初始化一个预览layer
    AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    //设置视频的显示比例
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //设置frame
    [layer setFrame:self.view.layer.bounds];
    
    [self.preview.layer addSublayer:layer];
    
    //启动扫描
    [self.session startRunning];
    
}
- (IBAction)cancel:(id)sender {
    [self stopRead];
}

//结束二维码扫描
-(void)stopRead{
    [self.session stopRunning];
}

-(void)result:(NSString *)res{
    [self.session stopRunning];
    //展示结果
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"result"];
    [vc setValue:res forKey:@"result"];
    [self.navigationController pushViewController:vc animated:YES];
    
}

//扫描到结果的输出
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count == 0) {
        return;
    }
    AVMetadataMachineReadableCodeObject *object = [metadataObjects firstObject];
    NSLog(@"%@", [object stringValue]);
    
    //当前不在主线程,更新UI要在主线程
    [self performSelectorOnMainThread:@selector(result:) withObject:[object stringValue] waitUntilDone:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
