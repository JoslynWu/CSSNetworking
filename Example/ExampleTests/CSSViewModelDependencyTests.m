//
//  CSSViewModelDependencyTests.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/24.
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
    requestIdThree,
    requestIdFour,
};

static NSInteger requestCount = 0;
static NSInteger operationCompleteCount = 0;

@interface CSSViewModelDependencyTests : XCTestCase <CSSViewModelDelegate>

@property (nonatomic, strong) CSSViewModel *vm;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *backIds;
@property (nonatomic, strong) NSArray<NSNumber *> *currentRids;

@end

@implementation CSSViewModelDependencyTests

- (void)setUp {
    [super setUp];
    
    __weak typeof(self) weakSelf = self;
    self.vm = [[CSSViewModel alloc] initWithDelegate:self addRequest:^(CSSViewModel *make) {
        [make addRequestWithId:requestIdOne config:^(CSSVMRequestItem * _Nonnull item) {
            item.request = [CSSNormalRequest new];
            item.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdTwo config:^(CSSVMRequestItem * _Nonnull item) {
            item.request = [CSSCacheRequest new];
            item.requestData = [weakSelf requestDataForRequestWithCode:@"tool"];
        }];
        
        [make addRequestWithId:requestIdThree config:^(CSSVMRequestItem * _Nonnull item) {
            item.request = [CSSNormalRequest new];
            item.requestData = [weakSelf requestDataForRequestWithCode:@"info"];
        }];
        
        [make addRequestWithId:requestIdFour config:^(CSSVMRequestItem * _Nonnull item) {
            item.request = [CSSNormalRequest new];
            item.requestData = [weakSelf requestDataForRequestWithCode:@"info"];
            item.independent = YES;
        }];
        
        make.requestComplete = ^(NSArray<NSNumber *> * _Nonnull rids) {
            operationCompleteCount++;
            weakSelf.currentRids = rids;
            CSS_POST_NOTIF
        };
    }];
    
    self.backIds = [NSMutableArray arrayWithCapacity:self.vm.count];
}

- (void)tearDown {
    requestCount = 0;
    operationCompleteCount = 0;
    [self.backIds removeAllObjects];
    [super tearDown];
}

- (void)testSuccessDependency {
    [self.vm addDependencyForRid:requestIdOne from:requestIdTwo success:^BOOL(CSSWebResponse * resp) {
        CSSNormalResponseData *respData = resp.processData;
        CSSDataModel *dataModel = respData.json;
        return [dataModel.contentCode isEqualToString:@"tool"];
    }];
    
    [self.vm addDependencyForRid:requestIdTwo from:requestIdThree success:^BOOL(CSSWebResponse * resp) {
        return YES;
    }];
    
    [self.vm sendAllRequest];
    
    CSS_WAIT
    XCTAssertTrue([self.backIds indexOfObject:@(requestIdOne)] > [self.backIds indexOfObject:@(requestIdTwo)]);
    XCTAssertTrue([self.backIds indexOfObject:@(requestIdTwo)] > [self.backIds indexOfObject:@(requestIdThree)]);
    
    XCTAssertTrue([self.currentRids containsObject:@(requestIdOne)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdThree)]);
    
    XCTAssertTrue([self.backIds containsObject:@(requestIdOne)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdThree)]);
    
    XCTAssertTrue(self.currentRids.count == self.backIds.count);
    XCTAssertTrue(operationCompleteCount == 1);
}

- (void)testFailureDependency {
    [self.vm addDependencyForRid:requestIdOne from:requestIdTwo success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm addDependencyForRid:requestIdTwo from:requestIdThree success:^BOOL(CSSWebResponse * resp) {
        return YES;
    }];
    
    [self.vm sendAllRequest];
    
    CSS_WAIT
    XCTAssertTrue([self.backIds indexOfObject:@(requestIdOne)] > [self.backIds indexOfObject:@(requestIdTwo)]);
    XCTAssertTrue([self.backIds indexOfObject:@(requestIdTwo)] > [self.backIds indexOfObject:@(requestIdThree)]);
    
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdOne)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdThree)]);
    
    XCTAssertTrue(![self.backIds containsObject:@(requestIdOne)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdThree)]);
    
    XCTAssertTrue(self.currentRids.count == self.backIds.count);
    XCTAssertTrue(requestCount == 2);
    XCTAssertTrue(operationCompleteCount == 1);
}

- (void)testMoreFailureDependency {
    [self.vm addDependencyForRid:requestIdOne from:requestIdTwo success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm addDependencyForRid:requestIdTwo from:requestIdThree success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm sendAllRequest];
    
    CSS_WAIT
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdOne)]);
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdThree)]);
    
    XCTAssertTrue(![self.backIds containsObject:@(requestIdOne)]);
    XCTAssertTrue(![self.backIds containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdThree)]);
    
    XCTAssertTrue(self.currentRids.count == self.backIds.count);
    XCTAssertTrue(requestCount == 1);
    XCTAssertTrue(operationCompleteCount == 1);
}

- (void)testMoreFailureMixingDependency {
    self.vm.itemInfos[@(requestIdFour)].independent = NO;
    [self.vm addDependencyForRid:requestIdOne from:requestIdTwo success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm addDependencyForRid:requestIdTwo from:requestIdThree success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm sendAllRequest];
    
    CSS_WAIT
    
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdOne)]);
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdThree)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdFour)]);
    
    XCTAssertTrue(![self.backIds containsObject:@(requestIdOne)]);
    XCTAssertTrue(![self.backIds containsObject:@(requestIdTwo)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdThree)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdFour)]);
    
    XCTAssertTrue(self.currentRids.count == self.backIds.count);
    XCTAssertTrue(requestCount == 2);
    XCTAssertTrue(operationCompleteCount == 1);
}

- (void)testMoreFailureDeepHierarchyDependency {
    self.vm.itemInfos[@(requestIdFour)].independent = NO;
    [self.vm addDependencyForRid:requestIdOne from:requestIdTwo success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm addDependencyForRid:requestIdTwo from:requestIdThree success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm addDependencyForRid:requestIdThree from:requestIdFour success:^BOOL(CSSWebResponse * resp) {
        return NO;
    }];
    
    [self.vm sendAllRequest];
    
    CSS_WAIT
    NSLog(@"---->%@, %@", self.currentRids, self.backIds);
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdOne)]);
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdTwo)]);
    XCTAssertTrue(![self.currentRids containsObject:@(requestIdThree)]);
    XCTAssertTrue([self.currentRids containsObject:@(requestIdFour)]);
    
    XCTAssertTrue(![self.backIds containsObject:@(requestIdOne)]);
    XCTAssertTrue(![self.backIds containsObject:@(requestIdTwo)]);
    XCTAssertTrue(![self.backIds containsObject:@(requestIdThree)]);
    XCTAssertTrue([self.backIds containsObject:@(requestIdFour)]);
    
    XCTAssertTrue(self.currentRids.count == self.backIds.count);
    XCTAssertTrue(requestCount == 1);
    XCTAssertTrue(operationCompleteCount == 1);
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
        [self.backIds addObject:@(rid)];
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
