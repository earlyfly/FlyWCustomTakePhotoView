//
//  GZPhotoCameraVC.h
//  PhotoDemo
//
//  Created by trs on 2023/7/11.
//  Copyright © 2023 yll. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^PhotoBlock)(UIImage *image);

@interface GZPhotoCameraVC : UIViewController

@property (nonatomic, copy) PhotoBlock imageblock;

@end

NS_ASSUME_NONNULL_END
