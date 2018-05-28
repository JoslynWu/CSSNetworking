//
//  CSSViewModelSingleRequetTests.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/2/7.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSNetworking.h"
#import "CSSNormalRequest.h"
#import "CSSUnitTestDefine.h"
#import "CSSCacheRequest.h"

typedef NS_ENUM(NSInteger, requestId) {
    requestIdOne = 1,
    requestIdTwo
};

static NSInteger requestCount = 0;

@interface CSSViewModelSingleRequetTests : XCTestCase <CSSViewModelDelegate>

@property (nonatomic, strong) CSSViewModel *vm;

@end

@implementation CSSViewModelSingleRequetTests

- (void)setUp {
    [super setUp];
    
    __weak typeof(self) weakSelf = self;
    self.vm = [[CSSViewModel alloc] initWithDelegate:self addRequest:^(CSSViewModel *make) {
        [make addRequestWithId:requestIdOne config:^(CSSVMRequestItem * _Nonnull item) {
            item.request = [CSSNormalRequest new];
            item.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdTwo config:^(CSSVMRequestItem * _Nonnull item) {
            item.independent = YES;
            item.request = [CSSCacheRequest new];
            item.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        make.requestComplete = ^(NSArray<NSNumber *> * _Nonnull rids) {
            XCTAssertTrue(rids.count > 0);
            XCTAssertTrue(requestCount == 1);
            CSS_POST_NOTIF
        };
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSingleRequestWithNoCache {
    CSSVMRequestItem *info = (CSSVMRequestItem *)[self.vm requestItemWithId:requestIdOne];
    ((CSSNormalRequestData *)info.requestData).contentCode = @"tool";
    [self.vm sendSingleRequestWithId:requestIdOne];
    
    CSS_WAIT
    
    requestCount--;
}

- (void)testSingleRequestWithCache {
    [self.vm sendSingleRequestWithId:requestIdTwo];
    
    CSS_WAIT
    
    requestCount--;
}

#pragma mark - ********************* action *********************
- (CSSWebRequestData *)requestDataForRequestWithCode:(NSString *)code {
    CSSNormalRequestData *requestData = [CSSNormalRequestData new];
    requestData.contentCode = code;
    CSSContentModel *content = [CSSContentModel new];
    content.title = @"content title";
    content.desc = @"content desc";
    CSSListModel *listOne = [CSSListModel new];
    listOne.title = @"list one";
    listOne.url = @"https://www.baidu.com";
    CSSListModel *listTwo = [CSSListModel new];
    listTwo.title = @"list two";
    listTwo.url = @"https://www.httpbin.com";
    content.list = @[listOne, listTwo];
    requestData.content = content;
    
    return requestData;
}

- (void)requestTestForOneWithResp:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
    XCTAssertTrue(respData.json.content);
    XCTAssertTrue(respData.json.content.list.count > 0);
    CSSDataModel *dataModel = respData.json;
    XCTAssertTrue([dataModel.contentCode isEqualToString:@"tool"]);
    CSSListModel *materModel = dataModel.content.list.firstObject;
    XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
    XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
}

#pragma mark  -  CSSViewModelDelegate
- (void)viewModel:(CSSViewModel *)vm complete:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        [self requestTestForOneWithResp:resp requestId:rid];
        CSSVMRequestItem *info = [vm requestItemWithId:rid];
        if (!info.independent) {
            XCTAssertTrue(rid == 1);
        }
    }
    if (!(resp.respType == CACHE)) {
        requestCount++;
    }
}

- (void)viewModel:(CSSViewModel *)vm success:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForOneWithResp:resp requestId:rid];
    }
}

- (void)viewModel:(CSSViewModel *)vm failure:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    XCTAssert(NO, @"网络异常，请检查");
}

- (void)viewModel:(CSSViewModel *)vm cache:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdTwo) {
        XCTAssertTrue(resp.respType == CACHE);
        [self requestTestForOneWithResp:resp requestId:rid];
    }
}



@end
