//
//  NSObject+CSSModel.m
//  CSSModel
//
//  Created by Joslyn Wu on 2018/1/21.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "CSSModel.h"
#import <objc/runtime.h>

static NSString *const CSSModelPropertyClassKey = @"class";
static NSString *const CSSModelPropertySubClassKey = @"subclass";

@interface NSObject ()

@property (nonatomic, readonly) NSDictionary<NSString *, Class> *css_instanceCodableProperties;

@end


@implementation NSObject (CSSModel)

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)css_modelWithJson:(id)json {
    if ( nil == json || [json isKindOfClass:[NSNull class]]) { return nil; }
    NSDictionary *dict = [self _css_dictionaryWithJSON:json];
    return [self css_modelWithDictionary:dict];
}

+ (NSArray *)css_modelsWithArray:(NSArray *)array {
    NSMutableArray * objects = [NSMutableArray array];
    for ( NSDictionary * obj in array ) {
        if ( [obj isKindOfClass:[NSDictionary class]] ) {
            id convertedObj = [self css_modelWithDictionary:obj];
            if ( convertedObj ) {
                [objects addObject:convertedObj];
            }
        } else {
            [objects addObject:obj];
        }
    }
    return [objects copy];
}

+ (instancetype)css_modelWithDictionary:(NSDictionary *)dictionary {
    id object = [[self alloc] init];
    NSDictionary * properties = [object css_instanceCodableProperties];
    for ( __unsafe_unretained NSString *property in properties ){
        id value = dictionary[property];
        Class clazz = properties[property][CSSModelPropertyClassKey];
        Class subClazz = properties[property][CSSModelPropertySubClassKey];
        if ( value ) {
            id convertedValue = value;
            if ( [value isKindOfClass:[NSArray class]] ) {
                if ( subClazz != NSNull.null ) {
                    convertedValue = [subClazz css_modelsWithArray:value];
                } else {
                    NSLog(@"[CSSModel] You should add a protocol that is the same as the element name to NSArray. <e.g. list<SubModel>> ");
                    // 如果有必要可以这里将类型指定交给用户。
                }
            } else if ( [value isKindOfClass:[NSDictionary class]] ) {
                convertedValue = [clazz css_modelWithDictionary:value];
            }
            
            if ( convertedValue && ![convertedValue isKindOfClass:[NSNull class]] ) {
                [object setValue:convertedValue forKey:property];
                if ( ![convertedValue isKindOfClass:clazz] ) {
                    // @"Expected '%@' to be a %@, but was actually a %@"
                    NSLog( @"[CSSModel] The type of '%@' in <%@> is <%@>, but not compatible with expected <%@>, please see detail in the <AutoModelCoding> protocol.", property, [self class], [value class], clazz );
                }
            }
        }
    }
    return object;
}

- (NSObject *)css_JSONObject {
    NSMutableArray *mArr = [NSMutableArray array];
    if ([self isKindOfClass:[NSArray class]]) {
        for (NSObject *item in (NSArray *)self) {
            [mArr addObject:item.css_JSONObject ?: item];
        }
        return mArr.copy;
    }
    
    NSDictionary *tempDict = [self.class _css_dictionaryWithJSON:self];
    if (tempDict) {
        return tempDict;
    }
    NSDictionary *codableProperties = [self css_instanceCodableProperties];
    if (codableProperties.count <= 0) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (__unsafe_unretained NSString *key in codableProperties) {
        id value = [self valueForKey:key];
        if (value) {
            Class clz = codableProperties[key][CSSModelPropertyClassKey];
            if ([clz isSubclassOfClass:NSValue.class]
                || [clz isSubclassOfClass:NSString.class]
                || [clz isSubclassOfClass:NSDictionary.class])
            {
                if (value) dict[key] = value;
            } else if ([clz isSubclassOfClass:[NSArray class]]) {
                NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:[value count]];
                for (id subObj in value) {
                    [mArr addObject:[subObj css_JSONObject]];
                }
                dict[key] = mArr;
            } else {
                if (value) dict[key] = [value css_JSONObject];
            }
        }
    }
    return dict;
}

- (instancetype)css_clone {
    NSObject *temp = [self css_JSONObject];
    NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:kNilOptions error:nil];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if (![dict isKindOfClass:[NSDictionary class]]) { dict = nil; }
    return [[self class] css_modelWithDictionary:dict];
}

#pragma mark  -  private
+ (NSDictionary *)_css_dictionaryWithJSON:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding : NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        NSError *error;
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

#pragma mark  -  Reference AutoCoding
//  https://github.com/nicklockwood/AutoCoding
+ (NSDictionary *)css_codableProperties {
    unsigned int propertyCount;
    __autoreleasing NSMutableDictionary *codableProperties = [NSMutableDictionary dictionary];
    objc_property_t *properties = class_copyPropertyList(self, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        __autoreleasing NSString *key = @(propertyName);
        Class propertyClass = nil;
        Class propertySubClass = nil;
        char *typeEncoding = property_copyAttributeValue(property, "T");
        switch (typeEncoding[0]) {
            case '@': {
                if (strlen(typeEncoding) >= 3) {
                    char *className = strndup(typeEncoding + 2, strlen(typeEncoding) - 3);
                    __autoreleasing NSString *name = @(className);
                    __autoreleasing NSString *clazzName = nil;
                    __autoreleasing NSString *protocolName = nil;
                    NSRange range = [name rangeOfString:@"<"];
                    if (range.location != NSNotFound) {
                        clazzName = [name substringToIndex:range.location];
                        NSRange nexRange = [name rangeOfString:@">"];
                        if ( nexRange.location != NSNotFound ) {
                            protocolName = [name substringWithRange:NSMakeRange(NSMaxRange(range), nexRange.location-NSMaxRange(range))];
                            propertySubClass = NSClassFromString(protocolName) ?: [NSObject class];
                        }
                    } else {
                        clazzName = name;
                    }
                    propertyClass = NSClassFromString(clazzName) ?: [NSObject class];
                    free(className);
                }
                break;
            }
            case 'c':
            case 'i':
            case 's':
            case 'l':
            case 'q':
            case 'C':
            case 'I':
            case 'S':
            case 'L':
            case 'Q':
            case 'f':
            case 'd':
            case 'B': {
                propertyClass = [NSNumber class];
                break;
            }
            case '{': {
                propertyClass = [NSValue class];
                break;
            }
        }
        free(typeEncoding);
        
        if (propertyClass) {
            //check if there is a backing ivar
            char *ivar = property_copyAttributeValue(property, "V");
            char *readonly = property_copyAttributeValue(property, "R");
            if (ivar) {
                //check if ivar has KVC-compliant name
                __autoreleasing NSString *ivarName = @(ivar);
                if (!readonly && ([ivarName isEqualToString:key] || [ivarName isEqualToString:[@"_" stringByAppendingString:key]])) {
                    //no setter, but setValue:forKey: will still work
                    Class subClass = propertySubClass ?: NSNull.null;
                    codableProperties[key] = @{CSSModelPropertyClassKey:propertyClass, CSSModelPropertySubClassKey: subClass};
                }
                free(ivar);
            } else {
                //check if property is dynamic and readwrite
                char *dynamic = property_copyAttributeValue(property, "D");
                if (dynamic && !readonly) {
                    //no ivar, but setValue:forKey: will still work
                    Class subClass = propertySubClass ?: NSNull.null;
                    codableProperties[key] = @{CSSModelPropertyClassKey:propertyClass, CSSModelPropertySubClassKey: subClass};
                }
                free(dynamic);
            }
            free(readonly);
        }
    }
    
    free(properties);
    return codableProperties;
}

- (NSDictionary *)css_instanceCodableProperties {
    __autoreleasing NSDictionary *codableProperties = objc_getAssociatedObject([self class], _cmd);
    if (!codableProperties) {
        codableProperties = [NSMutableDictionary dictionary];
        Class subclass = [self class];
        while (subclass != [NSObject class]) {
            [(NSMutableDictionary *)codableProperties addEntriesFromDictionary:[subclass css_codableProperties]];
            subclass = [subclass superclass];
        }
        codableProperties = [NSDictionary dictionaryWithDictionary:codableProperties];
        objc_setAssociatedObject([self class], _cmd, codableProperties, OBJC_ASSOCIATION_RETAIN);
    }
    
    return codableProperties;
}

#pragma mark  -  NSSecureCoding
- (void)css_setWithCoder:(NSCoder *)aDecoder{
    BOOL secureAvailable = [aDecoder respondsToSelector:@selector(decodeObjectOfClass:forKey:)];
    BOOL secureSupported = [[self class] supportsSecureCoding];
    NSDictionary *properties = self.css_instanceCodableProperties;
    for (NSString *key in properties) {
        id object = nil;
        Class propertyClass = properties[key][CSSModelPropertyClassKey];
        if (secureAvailable) {
            object = [aDecoder decodeObjectOfClass:propertyClass forKey:key];
        } else {
            object = [aDecoder decodeObjectForKey:key];
        } if (object) {
            if (secureSupported && ![object isKindOfClass:propertyClass] && object != [NSNull null]) {
                [NSException raise:@"[CSSModel] CSSModelCodingException" format:@"Expected '%@' to be a %@, but was actually a %@", key, propertyClass, [object class]];
            }
            [self setValue:object forKey:key];
        }
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    [self css_setWithCoder:aDecoder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in self.css_instanceCodableProperties) {
        id object = [self valueForKey:key];
        if (object) [aCoder encodeObject:object forKey:key];
    }
}

@end
