//
//  CSSWebRequestTask.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSWebRequestTask.h"

@implementation CSSWebRequestTask

- (void) destroy {
    [self.dataTask cancel];
}

- (NSString *) brief {
    return @"DefaultTask";
}

@end


@implementation CSSWebRequestKernel

@end

