//
//  GZPhotoCameraVC.m
//  PhotoDemo
//
//  Created by trs on 2023/7/11.
//  Copyright © 2023 yll. All rights reserved.
//

#import "GZPhotoCameraVC.h"
#import <Photos/Photos.h>
#import "UIImage+info.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface GZPhotoCameraVC ()<AVCaptureMetadataOutputObjectsDelegate,AVCapturePhotoCaptureDelegate,CAAnimationDelegate>


//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property (nonatomic, strong) AVCaptureSession *session;
//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property (nonatomic, strong) AVCaptureDevice *device;
//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//输出
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutPut;
//图像预览层，实时显示捕获的图像
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


//上方功能区
@property (nonatomic, strong) UIView *topView;
//下方功能区
@property (nonatomic, strong) UIView *bottomView;
//拍照
@property (nonatomic, strong) UIButton *PhotoButton;
//取消
@property (nonatomic, strong) UIButton *cancleButton;
//切换摄像头
@property (nonatomic, strong) UIButton *changeButton;
//确定选择当前照片
@property (nonatomic, strong) UIButton *selectButton;
//重新拍照
@property (nonatomic, strong) UIButton *reCamButton;
//照片加载视图
@property (nonatomic, strong) UIImageView *imageView;
//对焦区域
@property (nonatomic, strong) UIImageView *focusView;
//拍到的照片
@property (nonatomic, strong) UIImage *image;
//是否可以拍照
@property (nonatomic, assign) BOOL canCa;
//照片目标区域边框
@property (nonatomic, strong) UIImageView *kuangImgView;
//提示文案
@property (nonatomic, strong) UILabel *tishiLabel;

@end

@implementation GZPhotoCameraVC

#pragma mark - Life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        _canCa = [self canUserCamear];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    if (_canCa) {
        [self customCamera];
        [self customUI];
    }else{
        return;
    }
}

#pragma mark - 检查相机权限
- (BOOL)canUserCamear{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"请打开相机权限" message:@"请前往系统设置-隐私-相机打开权限" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                
            }
        }];
        [alertVC addAction:sureAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:cancelAction];
        
        [self presentViewController:alertVC animated:YES completion:nil];
        
        return NO;
    }
    else{
        return YES;
    }
    return YES;
}

#pragma mark - 自定义视图
- (void)customUI {

    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.focusView];
    [self.view addSubview:self.kuangImgView];
    [self.view addSubview:self.tishiLabel];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
}
#pragma mark - 自定义相机
- (void)customCamera{
    
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc]init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    if ([self.session canAddOutput:self.photoOutPut]) {
        [self.session addOutput:self.photoOutPut];
    }
    
    [self.view.layer addSublayer:self.previewLayer];
    
    //开始启动
    [self.session startRunning];
    if ([self.device lockForConfiguration:nil]) {
        //自动白平衡
        if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        
        [self.device unlockForConfiguration];
    }
    
}

#pragma mark - 聚焦
- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    if (!self.session.isRunning) {
        return;
    }
    
    CGPoint point = [gesture locationInView:gesture.view];
    
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        self.focusView.center = point;
        _focusView.hidden = NO;
        
        self.focusView.alpha = 1;
        [UIView animateWithDuration:0.2 animations:^{
            self.focusView.transform = CGAffineTransformMakeScale(1.25f, 1.25f);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                self.focusView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            } completion:^(BOOL finished) {
                [self hiddenFocusAnimation];
            }];
        }];
    }
    
}
#pragma mark - 拍照
- (void)shutterCamera
{
    
    AVCaptureConnection * videoConnection = [self.photoOutPut connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
//    NSDictionary *outputSettings = [[NSDictionary alloc] init];
//    AVCapturePhotoSettings* setting = [AVCapturePhotoSettings
//    photoSettingsWithFormat:outputSettings];
//    // 设置闪光灯打开。注意，执行这句代码时闪光灯并不会打开，而是进行拍照时会自动打开，闪烁，然后关闭
//    setting.flashMode = AVCaptureFlashModeAuto;
//    // 拍照，照片在代理方法里获取
//    [self.ImageOutPut capturePhotoWithSettings:setting delegate:self];
    
    AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
    [self.photoOutPut capturePhotoWithSettings:set delegate:self];

}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhoto:(nonnull AVCapturePhoto *)photo error:(nullable NSError *)error {
    
    NSData *data = [photo fileDataRepresentation];
    self.image = [UIImage imageWithData:data];
    

    [self.session stopRunning];
    [self.view insertSubview:self.imageView belowSubview:self.topView];
    NSLog(@"image size = %@",NSStringFromCGSize(self.image.size));
    self.PhotoButton.alpha = 0;
    self.reCamButton.alpha = 1;
    self.selectButton.alpha = 1;
    
    // 保存图片到相册
    //UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

//#pragma - 保存至相册
//- (void)saveImageToPhotoAlbum:(UIImage*)savedImage
//{
//
//    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
//
//}
//// 指定回调方法
//
//- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo{
//    if(error){
//
//        NSLog(@"保存图片失败: %@", error);
//    }
//}

#pragma mark - 取消 返回上级
-(void)cancle{
    [self.imageView removeFromSuperview];
    [self.session stopRunning];
    [self dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark - 重新拍照
- (void)retakeNewPhoto {
    self.imageView.image = nil;
    [self.imageView removeFromSuperview];
    [self.session startRunning];
    self.PhotoButton.alpha = 1;
    self.reCamButton.alpha = 0;
    self.selectButton.alpha = 0;
}


#pragma mark - 选择照片 返回上级
- (void)selectImage {
    
    // 压缩图片尺寸像素
    CGFloat width = ScreenWidth;
    CGFloat height = self.image.size.height * width / self.image.size.width;
    UIImage *image = [UIImage image:self.image scaleToSize:CGSizeMake(width, height)];
    
    // 裁减指定区域
    CGFloat toWidth = 226;
    CGFloat toHeight = 360;
    CGFloat x = (width - toWidth) / 2;
    CGFloat y = (height - toHeight) / 2;
    CGRect rect = CGRectMake(x, y, toWidth, toHeight);
    image = [UIImage imageFromImage:image inRect:rect];
    
    // 旋转图片
    image = [UIImage imageWithCGImage:image.CGImage
                                    scale:image.scale
                              orientation:UIImageOrientationLeft];
        
    self.image = image;
    
    // 回传目标图片，并返回
    self.imageblock(self.image);
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

// 隐藏聚焦视图
- (void)hiddenFocusAnimation{
    [UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
    [UIView setAnimationDelay:3];
    self.focusView.alpha = 0;
    [UIView setAnimationDuration:0.5f];//动画时间
    [UIView commitAnimations];
    
}


#pragma mark - Setter & Getter
// 上方功能区
- (UIView *)topView {
    if (!_topView ) {
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 50)];
        _topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        [_topView addSubview:self.cancleButton];
        [_topView addSubview:self.changeButton];
    }
    return _topView;
}

// 取消
- (UIButton *)cancleButton {
    if (!_cancleButton) {
        _cancleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancleButton.frame = CGRectMake(ScreenWidth-40, 15, 30, 30);
        [_cancleButton setImage:[UIImage imageNamed:@"cancelPhoto"] forState:(UIControlStateNormal)];
        [_cancleButton addTarget:self action:@selector(cancle) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _cancleButton ;
}

// 下方功能区
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight-80, ScreenWidth, 80)];
        _bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        [_bottomView addSubview:self.reCamButton];
        [_bottomView addSubview:self.PhotoButton];
        [_bottomView addSubview:self.selectButton];
    }
    return _bottomView;
}

// 重拍
- (UIButton *)reCamButton {
    if (!_reCamButton) {
        _reCamButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reCamButton.frame = CGRectMake(40, 25, 80, 30);
        [_reCamButton addTarget:self action:@selector(retakeNewPhoto) forControlEvents:UIControlEventTouchUpInside];
        [_reCamButton setTitle:@"重新拍照" forState:UIControlStateNormal];
        _reCamButton.transform = CGAffineTransformMakeRotation(M_PI/2);
        [_reCamButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _reCamButton.alpha = 0;
    }
    return _reCamButton;
}

// 拍照
- (UIButton *)PhotoButton {
    if (!_PhotoButton) {
        _PhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _PhotoButton.frame = CGRectMake(ScreenWidth/2.0-30, 10, 60, 60);
        [_PhotoButton setImage:[UIImage imageNamed:@"photograph"] forState: UIControlStateNormal];
        [_PhotoButton addTarget:self action:@selector(shutterCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _PhotoButton;
}

// 确认选择拍照
- (UIButton *)selectButton {
    if (!_selectButton) {
        _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectButton.frame = CGRectMake(ScreenWidth-120, 25, 80, 30);
        [_selectButton addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
        [_selectButton setTitle:@"选择照片" forState:UIControlStateNormal];
        _selectButton.transform=CGAffineTransformMakeRotation(M_PI/2);
        [_selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _selectButton.alpha = 0;
    }
    return _selectButton;
}

// 加载拍照结果照片的视图
- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc]initWithFrame:self.previewLayer.frame];
        [_imageView setContentMode:UIViewContentModeScaleAspectFit];
        _imageView.image = _image;
    }
    return _imageView;
}

// 对焦区域
- (UIImageView *)focusView{
    if (_focusView == nil) {
        _focusView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.image = [UIImage imageNamed:@"foucs80pt"];
        _focusView.hidden = YES;
    }
    return _focusView;
}

// 采集及最终裁减区域框
- (UIImageView *)kuangImgView {
    if (_kuangImgView == nil) {
        _kuangImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0,  226, 360)];
        _kuangImgView.center = self.view.center;
        _kuangImgView.image = [UIImage imageNamed:@"photoKuang"];
    }
    return _kuangImgView;
}

// 提示文案
- (UILabel *)tishiLabel {
    
    if (_tishiLabel == nil) {
        _tishiLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth*0.5, 60)];
        _tishiLabel.center = self.view.center;
        _tishiLabel.text = @"请将身份证置于此区域\n尝试对其边缘";
        _tishiLabel.textColor = [UIColor whiteColor];
        _tishiLabel.numberOfLines = 0;
        _tishiLabel.textAlignment = NSTextAlignmentCenter;
        _tishiLabel.font = [UIFont systemFontOfSize:15];
        _tishiLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
        
    }
    
    return _tishiLabel;
}

// 使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
- (AVCaptureVideoPreviewLayer *)previewLayer{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
        _previewLayer.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
//        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return  _previewLayer;
}

// 采集输出
-(AVCapturePhotoOutput *)photoOutPut{
    if (_photoOutPut == nil) {
        _photoOutPut = [[AVCapturePhotoOutput alloc] init];
    }
    return _photoOutPut;
}

// 初始化输入
-(AVCaptureDeviceInput *)input{
    if (_input == nil) {
        
        _input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
    }
    return _input;
}

// 使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
-(AVCaptureDevice *)device{
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

@end

