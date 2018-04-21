//
//  CSSNetworkingHandle.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/1/30.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSNetworkingHandle.h"
#import "CSSUnitTestDefine.h"
#import <CSSModel/CSSModel.h>

@implementation CSSNetworkingHandle

- (NSDictionary *)manager:(CSSNetworkingManager *)manager globalHeaderForTask:(CSSWebRequestTask *)task {
    
    return @{};
}

- (void)manager:(CSSNetworkingManager *)manager globalSuccessHandleForTask:(CSSWebRequestTask *)task {
    
}

- (void)manager:(CSSNetworkingManager *)manager globalFailureHandleForTask:(CSSWebRequestTask *)task {
    
}

- (BOOL)manager:(CSSNetworkingManager *)manager strictSuccessForResponse:(CSSWebResponse *)resp {
    return (resp.respType == SUCCESS);
}

- (CSSWebResponseData *)manager:(CSSNetworkingManager *)manager customProcessForResponse:(CSSWebResponse *)resp {
    return [resp.task.webRequest.responseDataClass css_modelWithJson:resp.originalData];
}

- (id)manager:(CSSNetworkingManager *)manager encryptData:(id)data {
    return data;
}

- (id)manager:(CSSNetworkingManager *)manager decryptData:(id)data {
    return data;
}

@end
