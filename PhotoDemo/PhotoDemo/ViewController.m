//
//  ViewController.m
//  PhotoDemo
//
//  Created by yll on 2017/11/9.
//  Copyright © 2017年 yll. All rights reserved.
//

#import "ViewController.h"
#import "DDPhotoViewController.h"
#import "GZPhotoCameraVC.h"
#import "GZIDCardTakePhotoVC.h"
#import "Masonry.h"

@interface ViewController ()

//展示身份证图片用
@property (nonatomic, strong) UIImageView *frontImgView;
@property (nonatomic, strong) UIImageView *backImgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.frontImgView];
    [self.frontImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.frontImgView.mas_width).multipliedBy(226.0/360);
        make.bottom.equalTo(self.view.mas_centerY).inset(10);
    }];
    
    
    
    [self.view addSubview:self.backImgView];
    [self.backImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.width.height.equalTo(self.frontImgView);
        make.top.equalTo(self.frontImgView.mas_bottom).inset(20);
    }];
}


- (void)gotoCamera:(UIGestureRecognizer *)sender {
    
    UIAlertController *alertController = [[UIAlertController alloc]init];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // 来自PhotoView第三方：https://gitee.com/dumdum/PhotoDemo
        // 使用的是老的api实现，且存在裁减误差。不建议使用【❌❌❌过渡版本❌❌❌】
//        DDPhotoViewController *vc = [[DDPhotoViewController alloc] init];
//        vc.imageblock = ^(UIImage *image) {
//            self.imgView.image = image;
//        };
        
//        // 根据PhotoView灵感修改调整而来，能正确裁减，无废弃api的警告【⚠️⚠️⚠️过渡版本⚠️⚠️⚠️】
//        GZPhotoCameraVC *vc = [[GZPhotoCameraVC alloc] init];
//        vc.imageblock = ^(UIImage *image) {
//            self.imgView.image = image;
//        };
        
        // 根据PhotoView灵感修改调整而来，能正确裁减，无废弃api的警告【✅✅✅最终版本✅✅✅】
        UIImageView *imgV = (UIImageView *)sender.view;
        GZIDCardTakePhotoVC *vc = [[GZIDCardTakePhotoVC alloc] init];
        vc.idCardType = [imgV isEqual:self.backImgView] ? GZIDCardTakeTypeBack : GZIDCardTakeTypeFront;
        vc.photoCallback = ^(UIImage *image) {
            imgV.image = image;
        };
        
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [weakSelf presentViewController:vc animated:YES completion:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:photoAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (UIImageView *)setupImageView {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ms_id_upside"]];
    imageView.backgroundColor = [UIColor lightGrayColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotoCamera:)];
    [imageView addGestureRecognizer:tap];
    return imageView;
}

- (UIImageView *)frontImgView {
    if (!_frontImgView) {
        _frontImgView = [self setupImageView];
    }
    return _frontImgView;
}

- (UIImageView *)backImgView {
    if (!_backImgView) {
        _backImgView = [self setupImageView];
    }
    return _backImgView;
}

@end

