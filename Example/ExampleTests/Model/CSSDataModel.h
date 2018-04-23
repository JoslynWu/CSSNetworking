//
//  CSSDataModel.h
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/4/19.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSContentModel.h"

@interface CSSDataModel : NSObject

@property (nonatomic, copy) NSString *contentCode;
@property (nonatomic, strong) CSSContentModel *content;

@end
