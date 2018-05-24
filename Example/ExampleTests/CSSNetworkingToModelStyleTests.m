//
//  CSSNetworkingToModelStyleTests.m
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
#import "CSSRequestDefine.h"

@interface CSSNetworkingModelStyleRequest : CSSWebRequest

@end

@implementation CSSNetworkingModelStyleRequest

- (NSString *)urlForRequest {
    return [NSString stringWithFormat:@"%@%@", baseUrl, @"post"];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.responseDataClass = [CSSNormalResponseData class];
    return self;
}

- (CSSProcessStyle)processStyle {
    return YYModel;
}

@end


@interface CSSNetworkingToModelStyleTests : XCTestCase

@end

@implementation CSSNetworkingToModelStyleTests

- (void)setUp {
    [super setUp];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// 用YYModel处理数据
- (void)testRespWithYYModel {
    __block NSInteger callbackCount = 0;
    CSSNetworkingModelStyleRequest *request = [CSSNetworkingModelStyleRequest new];
    request.processStyle = YYModel;
    request.sucessBlock = ^(CSSWebResponse *resp) {
        callbackCount++;
        XCTAssertFalse(resp.respType == CACHE, @"检查是否开启了 placeHolder 和 cache");
        CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
        XCTAssertTrue(respData.json.content);
        XCTAssertTrue(respData.json.content.list.count > 0);
        CSSListModel *materModel = respData.json.content.list.firstObject;
        XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
        XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
        XCTAssertTrue(callbackCount == 1);
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(NO, @"网络异常，请检查");
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    XCTAssertTrue([request processStyle] == YYModel);
    CSS_WAIT
}

- (void)testRespWithMJExtension {
    __block NSInteger callbackCount = 0;
    CSSNormalRequest *request = [CSSNormalRequest new];
    request.processStyle = MJExtension;
    request.sucessBlock = ^(CSSWebResponse *resp) {
        callbackCount++;
        XCTAssertFalse(resp.respType == CACHE, @"检查是否开启了 placeHolder 和 cache");
        CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
        XCTAssertTrue(respData.json.content);
        XCTAssertTrue(respData.json.content.list.count > 0);
        CSSListModel *materModel = respData.json.content.list.firstObject;
        XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
        XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
        XCTAssertTrue(callbackCount == 1);
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(NO, @"网络异常，请检查");
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    XCTAssertTrue([request processStyle] == MJExtension);
    CSS_WAIT
}

- (void)testRespWithCustom {
    __block NSInteger callbackCount = 0;
    CSSNormalRequest *request = [CSSNormalRequest new];
    request.processStyle = Custom;
    request.sucessBlock = ^(CSSWebResponse *resp) {
        callbackCount++;
        XCTAssertFalse(resp.respType == CACHE, @"检查是否开启了 placeHolder 和 cache");
        CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
        XCTAssertTrue(respData.json.content);
        XCTAssertTrue(respData.json.content.list.count > 0);
        CSSListModel *materModel = respData.json.content.list.firstObject;
        XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
        XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
        XCTAssertTrue(callbackCount == 1);
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(NO, @"网络异常，请检查");
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    XCTAssertTrue([request processStyle] == Custom);
    CSS_WAIT
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



@end
