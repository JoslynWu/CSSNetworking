//
//  CSSViewModelCustomRequestTests.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/7.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSNetworking.h"
#import "CSSNormalRequest.h"
#import "CSSUnitTestDefine.h"
#import "CSSCacheRequest.h"

typedef NS_ENUM(NSInteger, requestId) {
    requestIdOne = 1,
    requestIdTwo,
    requestIdThree
};

static NSInteger requestCount = 0;

@interface CSSViewModelCustomRequestTests : XCTestCase <CSSMultiRequestViewModelDelegate>

@property (nonatomic, strong) CSSMultiRequestViewModel *vm;

@end

@implementation CSSViewModelCustomRequestTests

- (void)setUp {
    [super setUp];
    
    __weak typeof(self) weakSelf = self;
    self.vm = [[CSSMultiRequestViewModel alloc] initWithDelegate:self addRequest:^(vmCls *make) {
        [make addRequestWithId:requestIdOne config:^(CSSRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSNormalRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdTwo config:^(CSSRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSCacheRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdThree config:^(CSSRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSNormalRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"info"];
        }];
        
        make.requestComplete = ^(NSArray<NSNumber *> * _Nonnull rids) {
            XCTAssertTrue([rids containsObject:@(requestIdTwo)]);
            XCTAssertTrue([rids containsObject:@(requestIdThree)]);
            XCTAssertTrue(requestCount == 2);
            CSS_POST_NOTIF
        };
    }];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// 发送指定几个请求
- (void)testSendCustomRequest {
    [self.vm sendRequestWithIds:requestIdThree, requestIdTwo, nil];
    
    CSS_WAIT
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
    CSSNormalResponseData *respData = resp.processData;
    XCTAssertTrue(respData.json.content);
    XCTAssertTrue(respData.json.content.list.count > 0);
    CSSDataModel *dataModel = respData.json;
    XCTAssertTrue([dataModel.contentCode isEqualToString:@"tool"]);
    CSSListModel *materModel = dataModel.content.list.firstObject;
    XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
    XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
}

- (void)requestTestForThreeWithResp:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    CSSNormalResponseData *respData = resp.processData;
    XCTAssertTrue(respData.json.content);
    XCTAssertTrue(respData.json.content.list.count > 0);
    CSSDataModel *dataModel = respData.json;
    XCTAssertTrue([dataModel.contentCode isEqualToString:@"info"]);
    CSSListModel *materModel = dataModel.content.list.firstObject;
    XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
    XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
}

#pragma mark  -  CSSMultiRequestViewModelDelegate
- (void)viewModel:(vmCls *)vm complete:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        [self requestTestForOneWithResp:resp requestId:rid];
    } else if (rid == requestIdThree) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForThreeWithResp:resp requestId:rid];
    }
    XCTAssertTrue(rid == requestIdTwo || rid == requestIdThree);
    if (!(resp.respType == CACHE)) {
        requestCount++;
    }
}

- (void)viewModel:(vmCls *)vm success:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForOneWithResp:resp requestId:rid];
    } else if (rid == requestIdThree) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForThreeWithResp:resp requestId:rid];
    }
}

- (void)viewModel:(vmCls *)vm failure:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
}

- (void)viewModel:(vmCls *)vm cache:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdTwo) {
        XCTAssertTrue(resp.respType == CACHE);
    }
}


@end
