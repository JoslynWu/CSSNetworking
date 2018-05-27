//
//  CSSMultiRequestTests.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/2/6.
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

@interface CSSMultiRequestTests : XCTestCase <CSSViewModelDelegate>

@property (nonatomic, strong) CSSViewModel *vm;

@end

@implementation CSSMultiRequestTests

- (void)setUp {
    [super setUp];
    
    __weak typeof(self) weakSelf = self;
    self.vm = [[CSSViewModel alloc] initWithDelegate:self addRequest:^(CSSViewModel *make) {
        [make addRequestWithId:requestIdOne config:^(CSSVMRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSNormalRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdTwo config:^(CSSVMRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSCacheRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdThree config:^(CSSVMRequestInfo * _Nonnull requestInfo) {
            requestInfo.request = [CSSNormalRequest new];
            requestInfo.requestData = [weakSelf requestDataForRequestWithCode:@"info"];
        }];
        
        make.requestComplete = ^(NSArray<NSNumber *> * _Nonnull rids) {
            XCTAssertTrue([rids containsObject:@(requestIdOne)]);
            XCTAssertTrue([rids containsObject:@(requestIdTwo)]);
            XCTAssertTrue([rids containsObject:@(requestIdThree)]);
            XCTAssertTrue(requestCount == 3);
            CSS_POST_NOTIF
        };
    }];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSendMultiRequest {
    [self.vm sendAllRequest];

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

#pragma mark  -  CSSViewModelDelegate
- (void)viewModel:(CSSViewModel *)vm complete:(CSSWebResponse *)resp requestId:(NSInteger)rid {
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

- (void)viewModel:(CSSViewModel *)vm success:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdOne || rid == requestIdTwo) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForOneWithResp:resp requestId:rid];
    } else if (rid == requestIdThree) {
        XCTAssertFalse(resp.respType == CACHE);
        [self requestTestForThreeWithResp:resp requestId:rid];
    }
}

- (void)viewModel:(CSSViewModel *)vm failure:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    XCTAssert(NO, @"网络异常，请检查");
}

- (void)viewModel:(CSSViewModel *)vm cache:(CSSWebResponse *)resp requestId:(NSInteger)rid {
    if (rid == requestIdTwo) {
        XCTAssertTrue(resp.respType == CACHE);
    }
}


@end
