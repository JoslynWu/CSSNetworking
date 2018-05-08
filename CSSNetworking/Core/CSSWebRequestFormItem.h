//
//  CSSWebRequestFormItem.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSSWebRequestFormItem : NSObject

/**
 文件路径或者文件数据
 
 - 文件路径。NSURL或url的NSString形式。此时可以不指定 fileName 和 mimeType。
 - 文件数据。NSData。此时必须指定 fileName 和 mimeType。
 */
@property (nonatomic, copy) id<NSCopying> data;

/**
 名称。
 - e.g. "file"
 - 如果为nil,使用该item对应的key。
 */
@property (nonatomic, copy) NSString *name;

/** 文件名 */
@property (nonatomic, copy) NSString *fileName;

/** 文件类型。e.g. "image/jpeg" */
@property (nonatomic, copy) NSString *mimeType; 

@end
