//
//  GCDThrottle.m
//  GCDThrottle
//
//  Created by cyan on 16/5/24.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "GCDThrottle.h"

@implementation GCDThrottle

+ (NSMutableDictionary *)scheduledSources {
    static NSMutableDictionary *_sources = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _sources = [NSMutableDictionary dictionary];
    });
    return _sources;
}

void dispatch_throttle(NSTimeInterval threshold, GCDThrottleBlock block) {
    [GCDThrottle throttle:threshold block:block];
}

void dispatch_throttle_on_queue(NSTimeInterval threshold, dispatch_queue_t queue, GCDThrottleBlock block) {
    [GCDThrottle throttle:threshold queue:queue block:block];
}

+ (void)throttle:(NSTimeInterval)threshold block:(GCDThrottleBlock)block {
    [self throttle:threshold queue:THROTTLE_MAIN_QUEUE block:block];
}

+ (void)throttle:(NSTimeInterval)threshold queue:(dispatch_queue_t)queue block:(GCDThrottleBlock)block {
    
    NSString *key = [NSThread callStackSymbols][1];
    NSMutableDictionary *scheduledSources = self.scheduledSources;
    
    dispatch_source_t source = scheduledSources[key];
    
    if (source) {
        dispatch_source_cancel(source);
    }
    
    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(source, dispatch_time(DISPATCH_TIME_NOW, threshold * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(source, ^{
        block();
        dispatch_source_cancel(source);
        [scheduledSources removeObjectForKey:key];
    });
    dispatch_resume(source);
    
    scheduledSources[key] = source;
}

@end
