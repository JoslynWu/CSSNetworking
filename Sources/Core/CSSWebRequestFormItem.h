//
//  CSSWebRequestFormItem.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSSWebRequestFormItem : NSObject

@property (nonatomic, copy) id<NSCopying> data; // NSURL, NSString(url) or NSData。
@property (nonatomic, copy) NSString *name; // 如果不设置 name，则使用 task 的 formData<NSDictionary> 中 key 代替。
@property (nonatomic, copy) NSString *fileName; // 如果 data 是 NSData，不可为 nil。
@property (nonatomic, copy) NSString *mimeType; // 如果 data 是 NSData，不可为 nil。

@end
