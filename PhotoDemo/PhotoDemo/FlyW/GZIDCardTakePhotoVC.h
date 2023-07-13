//
//  GZIDCardTakePhotoVC.h
//  nmip
//
//  Created by trs on 2023/7/12.
//  Copyright © 2023 trs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    GZIDCardTakeTypeFront, // 身份证正面
    GZIDCardTakeTypeBack,  // 身份证背面国徽
} GZIDCardTakeType;

@interface GZIDCardTakePhotoVC : UIViewController

@property (nonatomic, assign) GZIDCardTakeType idCardType;
@property (nonatomic, copy) void(^photoCallback)(UIImage *image);

@end

NS_ASSUME_NONNULL_END
