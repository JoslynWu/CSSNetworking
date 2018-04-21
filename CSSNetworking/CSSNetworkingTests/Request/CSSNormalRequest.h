//
//  CSSNormalRequestData.h
//  

#import "CSSWebRequest.h"
#import "CSSDataModel.h"

@interface CSSNormalRequestData : CSSWebRequestData

@property(nonatomic ,copy) NSString *contentCode;
@property (nonatomic, strong) CSSContentModel *content;

@end


@interface CSSNormalResponseData : CSSWebResponseData

@property (nonatomic, strong) CSSDataModel *json;
@property (nonatomic, copy) NSString *currentPage;

@end

@interface CSSNormalRequest : CSSWebRequest

@end
