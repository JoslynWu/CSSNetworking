//
//  CSSListModel.h
//

#import <Foundation/Foundation.h>

@protocol CSSListModel <NSObject>

@end

@interface CSSListModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;

@end







