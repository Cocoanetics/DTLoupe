//
//  DTLoupeLayerDelegate.m
//  DTLoupe
//
//  Created by Joshua Grenon on 11/11/13.
//  Copyright 2013 Drobnik KG. All rights reserved.
//

#import "DTLoupeLayerDelegate.h"
#import "DTLoupeView.h"

// private interface for updating the loupe contents
@interface DTLoupeView (private)

- (void)refreshLoupeContent;

@end


@implementation DTLoupeLayerDelegate
{
	 DTLoupeView *_loupeView;
}

- (instancetype)initWithLoupeView:(DTLoupeView *)loupeView
{
    self = [super init];
	
    if (self)
	{
        _loupeView = loupeView;
    }
	
    return self;
}

- (void)displayLayer:(CALayer *)layer
{
	[_loupeView refreshLoupeContent];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
	// disable all animations
	return (id)[NSNull null];
}

@end
