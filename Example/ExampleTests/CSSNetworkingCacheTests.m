//
//  CSSCacheTests.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSWebRequest.h"
#import "CSSNormalRequest.h"
#import "CSSNetworkingManager.h"
#import "CSSContentModel.h"
#import "CSSNetworking.h"
#import "CSSCacheRequest.h"

#pragma mark  - TestCase
@interface CSSCacheTests : XCTestCase

@end

@implementation CSSCacheTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// 不使用缓存
- (void)testRequestNoCache {
    CSSNormalRequest *request = [CSSNormalRequest new];
    __weak typeof(self) weakSelf = self;
    request.sucessBlock = ^(CSSWebResponse *resp) {
        XCTAssertTrue(resp.respType == SUCCESS);
        [weakSelf checkResultWithResp:resp];
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    CSS_WAIT
}

// 使用缓存
- (void)testRequestCache {
    __block NSInteger count = 0;
    CSSCacheRequest *request = [CSSCacheRequest new];
    __weak typeof(self) weakSelf = self;
    request.fromCacheBlock = ^(CSSWebResponse *resp) {
        XCTAssertTrue(resp.respType == CACHE);
        [weakSelf checkResultWithResp:resp];
        count++;
    };
    request.sucessBlock = ^(CSSWebResponse *resp) {
        [weakSelf checkResultWithResp:resp];
        XCTAssertTrue(resp.respType == SUCCESS);
        count++;
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        count++;
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    CSS_WAIT
    XCTAssertTrue(count == 2);
    count = 0;
}

// 转发缓存 -- 直接设置属性
- (void)testForwardRequestCacheByNormalRequest {
    __block NSInteger count = 0;
    __block NSInteger cacheCount = 0;
    CSSNormalRequest *request = [CSSNormalRequest new];
    request.needCache = YES;
    request.needForwardCache = YES;
    __weak typeof(self) weakSelf = self;
    request.fromCacheBlock = ^(CSSWebResponse *resp) {
        XCTAssertTrue(resp.respType == CACHE);
        [weakSelf checkResultWithResp:resp];
        cacheCount++;
    };
    request.sucessBlock = ^(CSSWebResponse *resp) {
        count++;
        if (!resp.originalData.count) {
            return;
        }
        [weakSelf checkResultWithResp:resp];
        if (count == 1) {
            XCTAssertTrue(resp.respType == CACHE);
        } else {
            XCTAssertTrue(resp.respType == SUCCESS);
        }
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        count++;
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    CSS_WAIT
    XCTAssertTrue(count == 2);
    XCTAssertTrue(cacheCount == 0);
    count = 0;
    cacheCount = 0;
}

// 转发缓存 -- 子类重写
- (void)testForwardRequestCacheWithSubRequest {
    __block NSInteger count = 0;
    __block NSInteger cacheCount = 0;
    CSSForwarkCacheRequest *request = [CSSForwarkCacheRequest new];
    __weak typeof(self) weakSelf = self;
    request.fromCacheBlock = ^(CSSWebResponse *resp) {
        XCTAssertTrue(resp.respType == CACHE);
        [weakSelf checkResultWithResp:resp];
        cacheCount++;
    };
    request.sucessBlock = ^(CSSWebResponse *resp) {
        count++;
        if (!resp.originalData.count) {
            return;
        }
        [weakSelf checkResultWithResp:resp];
        if (count == 1) {
            XCTAssertTrue(resp.respType == CACHE);
        } else {
            XCTAssertTrue(resp.respType == SUCCESS);
        }
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        count++;
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    CSS_WAIT
    XCTAssertTrue(count == 2);
    XCTAssertTrue(cacheCount == 0);
    count = 0;
    cacheCount = 0;
}

#pragma mark - ********************* action *********************
- (CSSWebRequestData *)requestDataForRequest {
    CSSNormalRequestData *requestData = [CSSNormalRequestData new];
    requestData.contentCode = @"tool";
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

- (void)checkResultWithResp:(CSSWebResponse *)resp {
    CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
    XCTAssertTrue(respData.json.content);
    XCTAssertTrue(respData.json.content.list.count > 0);
    CSSListModel *materModel = respData.json.content.list.firstObject;
    XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
    XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
}



@end
