//
//  DTLoupeLayerDelegate.m
//  Pods
//
//  Created by Joshua Grenon on 11/11/13.
//
//

#import "DTLoupeLayerDelegate.h"

@interface DTLoupeLayerDelegate ()

@property (nonatomic, strong) UIView *view;

@end

@implementation DTLoupeLayerDelegate

- (id)initWithView:(UIView *)view {
    self = [super init];
    if (self != nil) {
        _view = view;
    }
    return self;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    
    SEL selector = NSSelectorFromString(@"drawBackgroundLayer:inContext:");
    if ([self.view respondsToSelector:selector] == NO)
        selector = @selector(drawLayer:inContext:);
    [self.view performSelector:selector withObject:layer withObject:(__bridge id)context];
}

@end
