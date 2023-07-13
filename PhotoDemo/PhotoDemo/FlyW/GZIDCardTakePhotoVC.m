//
//  GZIDCardTakePhotoVC.m
//  nmip
//
//  Created by trs on 2023/7/12.
//  Copyright © 2023 trs. All rights reserved.
//

#import "GZIDCardTakePhotoVC.h"
#import <Photos/Photos.h>
#import "Masonry.h"
#import "TZImagePickerController.h"
#import "UIImage+info.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface GZIDCardTakePhotoVC ()<AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate, UIGestureRecognizerDelegate, TZImagePickerControllerDelegate>


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
//相册
@property (nonatomic, strong) UIButton *selectPhotoBtn;
//确定选择当前照片
@property (nonatomic, strong) UIButton *sureButton;
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
@property (nonatomic, strong) UIImageView *clipAreaImgView;
@property (nonatomic, strong) UIImage *areaImage;
//提示文案
@property (nonatomic, strong) UILabel *tipsLabel;

@end

@implementation GZIDCardTakePhotoVC

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
        [self setupView];
    }else{
        return;
    }
}


#pragma mark - Events
// 取消 返回上级
-(void)cancleHandler {
    [self.imageView removeFromSuperview];
    [self.session stopRunning];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 重新拍照
- (void)retakeNewPhoto {
    self.imageView.image = nil;
    [self.imageView removeFromSuperview];
    
    [self configViewIsShouldTakePhoto:YES];
}

// 相册选择
- (void)selectPhotoHandler {
    
    TZImagePickerController *imagePickerVC = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    imagePickerVC.allowPickingVideo = NO;
    // 是否支持裁剪
    imagePickerVC.allowCrop = YES;
    // 设置裁剪区域
    CGFloat width = ScreenWidth;
    // 注意：裁剪区域的宽高和相册选择的裁剪区域宽高是相反的
    CGFloat height = self.areaImage.size.width * width / self.areaImage.size.height;
    CGFloat y = (ScreenHeight - height)/2.0;
    imagePickerVC.cropRect = CGRectMake(0, y, width, height);
    
    imagePickerVC.navigationBar.translucent = NO;
    imagePickerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    imagePickerVC.naviBgColor = [UIColor whiteColor];
    imagePickerVC.iconThemeColor = [UIColor blueColor];
    imagePickerVC.oKButtonTitleColorNormal = [UIColor blueColor];
    imagePickerVC.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    __weak typeof(self) weakSelf = self;
    [self presentViewController:imagePickerVC animated:YES completion:^{
        [weakSelf configViewIsShouldTakePhoto:NO];
    }];
}

// 拍照
- (void)shutterCamera {
    
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

// 选择照片 返回上级
- (void)selectImage {

    // 回传目标图片，并返回
    if (self.photoCallback) {
        self.photoCallback(self.image);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate
// 聚焦
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
        self.focusView.hidden = NO;
        
        self.focusView.alpha = 1;
        [UIView animateWithDuration:0.2 animations:^{
            self.focusView.transform = CGAffineTransformMakeScale(1.25f, 1.25f);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                self.focusView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.5 delay:3 options:0 animations:^{
                    self.focusView.alpha = 0;
                } completion:nil];
            }];
        }];
    }
    
}

// 将子视图的tap手势屏蔽
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.topView] || [touch.view isDescendantOfView:self.bottomView]) {
        return NO;
    }
    return YES;
}

#pragma mark - 拍照回调
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhoto:(nonnull AVCapturePhoto *)photo error:(nullable NSError *)error {
    
    NSData *data = [photo fileDataRepresentation];
    [self scaleAndClipImage:[UIImage imageWithData:data]];

    self.imageView.image = self.image;
    [self.view insertSubview:self.imageView belowSubview:self.topView];
    [self configViewIsShouldTakePhoto:NO];
    
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

#pragma mark - TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos {
    
    [self.imageView removeFromSuperview];
    
    self.image = photos.firstObject;
    self.imageView.image = self.image;
    [self.view insertSubview:self.imageView belowSubview:self.topView];
}

// 取消选择的回调
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    [self configViewIsShouldTakePhoto:YES];
}

#pragma mark - Private
// 检查相机权限
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

// 自定义视图
- (void)setupView {
    
    UIEdgeInsets insets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    CGFloat top = MAX(insets.top, 20);
    CGFloat bottom = insets.bottom;
    
    // 顶部操作区
    [self.view addSubview:self.topView];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view);
        make.height.mas_equalTo(50 + top);
    }];
    
    // 底部操作区
    [self.view addSubview:self.bottomView];
    [self.bottomView addSubview:self.PhotoButton];
    [self.bottomView addSubview:self.cancleButton];
    [self.bottomView addSubview:self.selectPhotoBtn];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.mas_equalTo(80 + bottom);
    }];
    [self.PhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView).offset(-bottom/2);
        make.centerX.equalTo(self.bottomView);
    }];
    
    
    [self.cancleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView).multipliedBy(0.5);
        make.centerY.equalTo(self.PhotoButton);
    }];
    
    [self.selectPhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView).multipliedBy(1.5);
        make.centerY.equalTo(self.PhotoButton);
    }];
    
    [self.view addSubview:self.clipAreaImgView];
    [self.clipAreaImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.areaImage.size);
        make.center.equalTo(self.view);
    }];
    
    [self.view addSubview:self.tipsLabel];
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.clipAreaImgView);
        make.centerX.equalTo(self.clipAreaImgView.mas_left).offset(-20);
    }];
    
    // 添加聚焦手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
}
// 自定义相机
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

// 缩放及裁减相机拍得的照片
- (void)scaleAndClipImage:(UIImage *)image {
    // 相机实际区域的尺寸
    CGFloat width = ScreenWidth;
    CGFloat height = image.size.height * width / image.size.width;
    
    // 缩放到屏幕宽对应尺寸的倍数
    CGFloat screenScale = 2.5;
    
    // 缩放的实际尺寸
    CGFloat targetW = width * screenScale;
    CGFloat targetH = height * screenScale;

    // 缩放后要裁减的区域
    CGFloat areaW = self.areaImage.size.width * screenScale;
    CGFloat areaH = self.areaImage.size.height * screenScale;

    // 缩放图片
    image = [UIImage image:image scaleToSize:CGSizeMake(targetW, targetH)];
    
    // 裁减指定区域
    CGFloat x = (targetW - areaW) / 2;
    CGFloat y = (targetH - areaH) / 2;
    CGRect rect = CGRectMake(x, y, areaW, areaH);
    image = [UIImage imageFromImage:image inRect:rect];
    
    // 旋转图片
    image = [UIImage imageWithCGImage:image.CGImage
                                    scale:image.scale
                              orientation:UIImageOrientationLeft];
        
    self.image = image;
}

- (void)configViewIsShouldTakePhoto:(BOOL)shouldTake {
    self.PhotoButton.hidden = !shouldTake;
    self.cancleButton.hidden = !shouldTake;
    self.selectPhotoBtn.hidden = !shouldTake;
    self.clipAreaImgView.hidden = !shouldTake;
    self.previewLayer.hidden = !shouldTake;
    self.tipsLabel.hidden = !shouldTake;
    self.reCamButton.hidden = shouldTake;
    self.sureButton.hidden = shouldTake;
    
    if (shouldTake) {
        [self.session startRunning];
    } else {
        [self.session stopRunning];
    }
}

#pragma mark - Setter & Getter
// 上方功能区
- (UIView *)topView {
    if (!_topView ) {
        _topView = [[UIView alloc] init];
        //_topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    }
    return _topView;
}

// 取消
- (UIButton *)cancleButton {
    if (!_cancleButton) {
        _cancleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancleButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        //[_cancleButton setImage:[UIImage imageNamed:@"cancelPhoto"] forState:UIControlStateNormal];
        [_cancleButton addTarget:self action:@selector(cancleHandler) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _cancleButton ;
}

// 下方功能区
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        //_bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    }
    return _bottomView;
}

// 拍照
- (UIButton *)PhotoButton {
    if (!_PhotoButton) {
        _PhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_PhotoButton setImage:[UIImage imageNamed:@"photograph"] forState: UIControlStateNormal];
        [_PhotoButton addTarget:self action:@selector(shutterCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _PhotoButton;
}

// 相册选择
- (UIButton *)selectPhotoBtn {
    if (!_selectPhotoBtn) {
        _selectPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectPhotoBtn setImage:[UIImage imageNamed:@"相册"] forState: UIControlStateNormal];
        [_selectPhotoBtn addTarget:self action:@selector(selectPhotoHandler) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectPhotoBtn;
}

// 重拍
- (UIButton *)reCamButton {
    if (!_reCamButton) {
        _reCamButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_reCamButton addTarget:self action:@selector(retakeNewPhoto) forControlEvents:UIControlEventTouchUpInside];
        [_reCamButton setTitle:@"重拍" forState:UIControlStateNormal];
        //_reCamButton.transform = CGAffineTransformMakeRotation(M_PI/2);
        [_reCamButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.bottomView addSubview:_reCamButton];
        [_reCamButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.cancleButton);
        }];
    }
    return _reCamButton;
}

// 确认选择拍照
- (UIButton *)sureButton {
    if (!_sureButton) {
        _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sureButton addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
        [_sureButton setTitle:@"确定" forState:UIControlStateNormal];
        //_sureButton.transform=CGAffineTransformMakeRotation(M_PI/2);
        [_sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.bottomView addSubview:_sureButton];
        [_sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.selectPhotoBtn);
        }];
    }
    return _sureButton;
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
    if (!_focusView) {
        _focusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera_foucs"]];
        [self.view addSubview:_focusView];
        _focusView.hidden = YES;
    }
    return _focusView;
}

// 采集及最终裁减区域框
- (UIImageView *)clipAreaImgView {
    if (_clipAreaImgView == nil) {
        _clipAreaImgView = [[UIImageView alloc] initWithImage:self.areaImage];
    }
    return _clipAreaImgView;
}

- (UIImage *)areaImage {
    if (!_areaImage) {
        _areaImage = [UIImage imageNamed:self.idCardType == GZIDCardTakeTypeBack ? @"idcard_area_back" : @"idcard_area_front"];
    }
    return _areaImage;
}

// 提示文案
- (UILabel *)tipsLabel {
    
    if (_tipsLabel == nil) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.text = self.idCardType == GZIDCardTakeTypeBack ? @"请拍摄身份证国徽面，并尝试对其边缘" : @"请拍摄身份证人像面，并尝试对其边缘";
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.numberOfLines = 0;
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.font = [UIFont systemFontOfSize:15];
        _tipsLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
        
    }
    
    return _tipsLabel;
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
