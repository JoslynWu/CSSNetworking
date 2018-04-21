//
//  CSSContentModel.m
//

#import "CSSContentModel.h"
#import <MJExtension/MJExtension.h>

@implementation CSSContentModel

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"list": @"CSSListModel"};
}

@end


@implementation NSArray (CSSListModel)

@end
