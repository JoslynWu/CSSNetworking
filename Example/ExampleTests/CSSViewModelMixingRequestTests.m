//
//  CSSViewModelMixingRequestTests.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/3.
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
static NSInteger operationCompleteCount = 0;

@interface CSSViewModelMixingRequestTests : XCTestCase <CSSMultiRequestViewModelDelegate>

@property (nonatomic, strong) CSSMultiRequestViewModel *vm;

@end

@implementation CSSViewModelMixingRequestTests

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
            operationCompleteCount++;
            if (operationCompleteCount == 1) {
                XCTAssertTrue([rids containsObject:@(requestIdOne)]);
                XCTAssertTrue([rids containsObject:@(requestIdTwo)]);
                XCTAssertTrue([rids containsObject:@(requestIdThree)]);
                XCTAssertTrue(requestCount == 3);
            } else if (operationCompleteCount == 2) {
                XCTAssertTrue([rids containsObject:@(requestIdThree)]);
                XCTAssertTrue(requestCount == (3 + 1));
            } else if (operationCompleteCount == 3) {
                XCTAssertTrue([rids containsObject:@(requestIdOne)]);
                XCTAssertTrue([rids containsObject:@(requestIdTwo)]);
                XCTAssertTrue([rids containsObject:@(requestIdThree)]);
                XCTAssertTrue(requestCount == (3 + 1 + 3));
            } else if (operationCompleteCount == 4) {
                XCTAssertTrue([rids containsObject:@(requestIdTwo)]);
                XCTAssertTrue([rids containsObject:@(requestIdThree)]);
                XCTAssertTrue(requestCount == (3 + 1 + 3 + 2));
            } else if (operationCompleteCount == 5) {
                XCTAssertTrue([rids containsObject:@(requestIdOne)]);
                XCTAssertTrue([rids containsObject:@(requestIdTwo)]);
                XCTAssertTrue(requestCount == (3 + 1 + 3 + 2 + 2));
                CSS_POST_NOTIF
            }
        };
    }];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 测试多组请求混合发送时，requestComplete回调是否有序。
 */
- (void)testSendMixingRequest {
    CSSOperation *operation1 =  [self.vm sendAllRequest];
    CSSOperation *operation2 = [self.vm sendSingleRequestWithId:requestIdThree];
    CSSOperation *operation3 = [self.vm sendAllRequest];
    CSSOperation *operation4 = [self.vm sendRequestWithIdArray:@[@(requestIdThree), @(requestIdTwo)]];
    CSSOperation *operation5 = [self.vm sendRequestWithIds:requestIdOne, requestIdTwo, nil];
//    operation2.queuePriority = NSOperationQueuePriorityVeryHigh;
    XCTAssertNotEqual(operation1, operation2);
    XCTAssertNotEqual(operation1, operation3);
    XCTAssertNotEqual(operation3, operation2);
    XCTAssertNotEqual(operation3, operation4);
    XCTAssertNotEqual(operation3, operation5);
    XCTAssertNotEqual(operation4, operation5);
    
    CSS_WAIT
    XCTAssertTrue(operationCompleteCount == 5);
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

- (void)requestTestForThreeWithResp:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
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
