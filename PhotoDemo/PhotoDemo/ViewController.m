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

@interface ViewController ()

//展示身份证图片用
@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 360, 226)];
    _imgView.backgroundColor = [UIColor redColor];
    _imgView.contentMode = UIViewContentModeScaleAspectFit;
    _imgView.center = self.view.center;
    
    _imgView.image = [UIImage imageNamed:@"ms_id_upside"];
    
    [self.view addSubview:_imgView];
    
    _imgView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotoCamera:)];
    
    [_imgView addGestureRecognizer:tap];
    
}


- (void)gotoCamera:(UIGestureRecognizer *)sender {
    
    UIAlertController *alertController = [[UIAlertController alloc]init];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
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
        GZIDCardTakePhotoVC *vc = [[GZIDCardTakePhotoVC alloc] init];
        vc.photoCallback = ^(UIImage *image) {
            self.imgView.image = image;
        };
        
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:photoAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

@end

