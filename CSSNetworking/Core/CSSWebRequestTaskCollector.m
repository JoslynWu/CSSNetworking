//
//  CSSWebRequestTaskCollector.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSWebRequestTaskCollector.h"

const NSInteger CSSRequestInvalidID = -1;
static unsigned long requestID = 0;

@interface CSSWebRequestTaskCollector()

@property(nonatomic, copy)NSMutableDictionary *requestCollector;

@end

@implementation CSSWebRequestTaskCollector

- (id) init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _requestCollector = [NSMutableDictionary new];
    return self;
}

-(CSSRequestID)insertRequestTask:(id<CSSWebRequesTaskProtocol>)request {
    if (!request) {
        return CSSRequestInvalidID;
    }
    CSSRequestID tid = [self nextUid];
    [self setValue:request withKey:[self packUid:tid]];
    return tid;
}

- (BOOL)removeRequestTaskWithUid:(CSSRequestID)tid {
    if (tid == CSSRequestInvalidID) {
        return NO;
    }
    
    id<NSCopying> key = [self packUid:tid];
    if ([self hasKey:key]) {
        [[self objectForKey:key] destroy];
        [self removeObjectForKey:key];
        return YES;
    }
    
    return NO;
}

- (id<CSSWebRequesTaskProtocol>)requestTaskForUid:(CSSRequestID)tid {
    return [self objectForKey:[self packUid:tid]];
}

#pragma mark - 生成tid
- (CSSRequestID) nextUid {
    return ++requestID;
}

#pragma mark - 将tid打包/解包
- (id<NSCopying>)packUid:(CSSRequestID)tid {
    return [NSNumber numberWithUnsignedLong:tid];
}

- (CSSRequestID)unpackUid:(id<NSCopying>)packedUid{
    NSNumber *number = (NSNumber *)packedUid;
    if (![number isKindOfClass:[NSNumber class]]) {
        return CSSRequestInvalidID;
    }
    
    return [number unsignedLongValue];
}

#pragma mark - setter/getter
- (id<CSSWebRequesTaskProtocol>)objectForKey:(id<NSCopying>)key{
    return [self.requestCollector objectForKey:key];
}

- (void) setValue:(id<CSSWebRequesTaskProtocol>)request withKey:(id<NSCopying>)key{
    [self.requestCollector setObject:request forKey:key];
}

- (void) removeObjectForKey:(id<NSCopying>)key {
    [self.requestCollector removeObjectForKey:key];
}

- (BOOL)hasKey:(id<NSCopying>)key {
    return ([self objectForKey:key] != nil);
}

#pragma mark - iterator
- (NSEnumerator *)keyEnumerator {
    return [self.requestCollector keyEnumerator];
}

@end

