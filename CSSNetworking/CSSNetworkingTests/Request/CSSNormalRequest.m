//
//  CSSNormalRequest.m
//

#import "CSSNormalRequest.h"
#import "CSSRequestDefine.h"

@implementation CSSNormalRequestData

@end

@implementation CSSNormalResponseData

@end

@implementation CSSNormalRequest

- (NSString *)urlForRequest {
    return [NSString stringWithFormat:@"%@%@", baseUrl, @"post"];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.responseDataClass = [CSSNormalResponseData class];
    return self;
}

@end
