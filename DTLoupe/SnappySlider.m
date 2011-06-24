//
//  SnappySlider.m
//  snappyslider
//
//  Created by Aaron Brethorst on 3/13/11.
//  Copyright (c) 2011 Aaron Brethorst
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SnappySlider.h"

@implementation SnappySlider
@synthesize detents;

- (id)initWithFrame:(CGRect)aFrame
{
	if ((self = [super initWithFrame:aFrame]))
	{
		rawDetents = NULL;
		detents = nil;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		rawDetents = NULL;
		detents = nil;
	}
	return self;
}

- (void)setDetents:(NSArray *)v
{
	if (detents == v)
	{
		return;
	}
	
	NSArray *newDetents = [[v sortedArrayUsingSelector:@selector(compare:)] copy];
	
	[detents release];
	detents = newDetents;
	
	if (nil != rawDetents)
	{
		free(rawDetents);
	}
	
	rawDetents = malloc(sizeof(int) * [detents count]);
	
	for (int i=0; i<[detents count]; i++)
	{
		rawDetents[i] = [[detents objectAtIndex:i] intValue];
	}
	
	self.minimumValue = [[detents objectAtIndex:0] floatValue];
	self.maximumValue = [[detents lastObject] floatValue];
}

- (void)setValue:(float)value animated:(BOOL)animated
{
	int bestDistance = INT_MAX;
	int bestFit = INT_MAX;
	
	for (int i=0; i < [detents count]; i++)
	{
		int candidate = rawDetents[i];
		int candidateDistance = abs(candidate - (int)value);
		
		if (candidateDistance < bestDistance)
		{
			bestFit = candidate;
			bestDistance = candidateDistance;
		}
	}
		
	[super setValue:(float)bestFit animated:animated];
}

- (void)dealloc
{
	self.detents = nil;
	free(rawDetents);
	[super dealloc];
}

@end
