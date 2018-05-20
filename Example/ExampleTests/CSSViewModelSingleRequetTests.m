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

@interface CSSViewModelSingleRequetTests : XCTestCase <CSSMultiRequestViewModelDelegate>

@property (nonatomic, strong) CSSMultiRequestViewModel *vm;

@end

@implementation CSSViewModelSingleRequetTests

- (void)setUp {
    [super setUp];
    
    __weak typeof(self) weakSelf = self;
    self.vm = [[CSSMultiRequestViewModel alloc] initWithDelegate:self addRequest:^(vmCls *make) {
        [make addRequestWithId:requestIdOne config:^(CSSRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSNormalRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdTwo config:^(CSSRequestInfo * _Nonnull requestInfo) {
            requestInfo.independent = YES;
            requestInfo.request = [CSSCacheRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
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
    CSSRequestInfo *info = (CSSRequestInfo *)[self.vm requestInfoWithId:requestIdOne];
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

#pragma mark  -  CSSMultiRequestViewModelDelegate
- (void)viewModel:(vmCls *)vm complete:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        [self requestTestForOneWithResp:resp requestId:rid];
        CSSRequestInfo *info = [vm requestInfoWithId:rid];
        if (!info.independent) {
            XCTAssertTrue(rid == 1);
        }
    }
    if (!(resp.respType == CACHE)) {
        requestCount++;
    }
}

- (void)viewModel:(vmCls *)vm success:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForOneWithResp:resp requestId:rid];
    }
}

- (void)viewModel:(vmCls *)vm failure:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
}

- (void)viewModel:(vmCls *)vm cache:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdTwo) {
        XCTAssertTrue(resp.respType == CACHE);
        [self requestTestForOneWithResp:resp requestId:rid];
    }
}



@end
