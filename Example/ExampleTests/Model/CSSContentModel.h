//
//  CSSContentModel.h
//

#import <Foundation/Foundation.h>
#import "CSSListModel.h"

@protocol CSSContentModel <NSObject>

@end

@interface CSSContentModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, strong) NSArray<CSSListModel> *list;

@end


@interface NSArray (CSSListModel) <CSSListModel>

@end
