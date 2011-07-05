//
//  DTLoupeView.m
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import "DTLoupeView.h"
#import <QuartzCore/QuartzCore.h>

@interface DTLoupeView ()

+ (CGSize)sizeForLoupeStyle:(DTLoupeStyle)style;
+ (CGPoint)offsetFromCenterForLoupeStyle:(DTLoupeStyle)style;

@property (nonatomic, retain) UIImage * loupeFrameImage; 
@property (nonatomic, retain) UIImage * loupeFrameBackgroundImage;
@property (nonatomic, retain) UIImage * loupeFrameMaskImage;

@end


@implementation DTLoupeView

// When a Circular Loupe appears, it is already drawn a visible size & then scales and moves to final size & position
// This creates the effect that it draws from below the tounchpoint
#define DTLoupeCircularStartTransform (CGAffineTransform){ 0.225, 0, 0, 0.225, 0, 20.0 }; // Scale to 0.225 & Translate x down 20

// With a Rectangular Loupe, it actually grows from a point above the touchpoint (centerpoint of cursor)
#define DTLoupeRectangularStartTransform (CGAffineTransform){ 0.225, 0, 0, 0.225, 0, 5.0 }; // Scale to 0.225 & Translate x down 5

// When a Loupe is dismissed, it scales down to nothing and disapears to the touchpoint (in general)
#define DTLoupeDismissedTransform (CGAffineTransform){ 0.01, 0, 0, 0.01, 0, 0.0 }; // Scale to 0.1

#define DTDefaultLoupeMagnification         1.20     // Match Apple's Magnification
#define DTDefaultLoupeAnimationDuration     0.15     // Match Apple's Duration




- (id)initWithStyle:(DTLoupeStyle)style
{
	CGSize size = [DTLoupeView sizeForLoupeStyle:style];
	CGRect frame = CGRectMake(0, 0, size.width, size.height);
	
	self = [super initWithFrame:frame];
	if (self)
	{
		self.contentMode = UIViewContentModeCenter;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		
		self.style = style;
	}
	
	return self;
}

- (void)dealloc
{
	[_loupeFrameImage release];
	[_loupeFrameBackgroundImage release];
	[_loupeFrameMaskImage release];
	
    [super dealloc];
}

#pragma mark Utilities

+ (CGSize)sizeForLoupeStyle:(DTLoupeStyle)style;
{
	switch (style) 
	{
		case DTLoupeStyleCircle:
			return CGSizeMake(127.0, 127.0);
			
		case DTLoupeStyleRectangle:
			return CGSizeMake(141.0, 55.0);
			
		case DTLoupeStyleRectangleWithArrow:
			return CGSizeMake(145.0, 59.0);
			
		default:
			return CGSizeZero;
	}
}

+ (CGPoint)offsetFromCenterForLoupeStyle:(DTLoupeStyle)style
{
	switch (style) 
	{
		case DTLoupeStyleCircle:
			return CGPointMake(0, -60.0);
			
		case DTLoupeStyleRectangle:
			return CGPointMake(0, -38.0);
			
		case DTLoupeStyleRectangleWithArrow:
			return CGPointMake(0, -38.0);
			
		default:
			return CGPointZero;
	}
}

+ (CGPoint)magnifiedImageOffsetForStyle:(DTLoupeStyle)style
{
	switch (style) 
	{
		case DTLoupeStyleCircle:
		{
			return CGPointMake(0, -4.0);
		}	
		case DTLoupeStyleRectangle:
		{
			return CGPointMake(0, 6.0);
		}
			
		case DTLoupeStyleRectangleWithArrow:
		{
			return CGPointMake(0, -18.0);
		}
			
		default:
			return CGPointZero;
	}
}

- (void)setImagesForStyle:(DTLoupeStyle)style
{
	switch (style) 
	{
		case DTLoupeStyleCircle:
		{
			self.loupeFrameBackgroundImage = [UIImage imageNamed:@"kb-loupe-lo.png"];
			self.loupeFrameMaskImage = [UIImage imageNamed:@"kb-loupe-mask.png"];
			self.loupeFrameImage = [UIImage imageNamed:@"kb-loupe-hi.png"];
			
			break;
		}	
		case DTLoupeStyleRectangle:
		{
			self.loupeFrameBackgroundImage = [UIImage imageNamed:@"kb-magnifier-ranged-lo-stemless.png"];
			self.loupeFrameMaskImage = [UIImage imageNamed:@"kb-magnifier-ranged-mask"];
			self.loupeFrameImage = [UIImage imageNamed:@"kb-magnifier-ranged-hi.png"];
			
			break;
		}
			
		case DTLoupeStyleRectangleWithArrow:
		{
			self.loupeFrameBackgroundImage = [UIImage imageNamed:@"kb-magnifier-ranged-lo.png"];
			self.loupeFrameMaskImage = [UIImage imageNamed:@"kb-magnifier-ranged-mask"];
			self.loupeFrameImage = [UIImage imageNamed:@"kb-magnifier-ranged-hi.png"];
			
			break;
		}
	}	
}




#pragma mark Interactivity

// Set TouchPoint as user moves around screen
- (void)setTouchPoint:(CGPoint)touchPoint
{
	_touchPoint = touchPoint;
	
	CGPoint newCenter = touchPoint;
	CGPoint offsetFromTouchPoint = [DTLoupeView offsetFromCenterForLoupeStyle:_style];
	
	newCenter.x += offsetFromTouchPoint.x;
	newCenter.y += offsetFromTouchPoint.y;
	
	// We do it here so that the centre of displayed "magnified image" 
    // captured in drawRect doesn't need to be adjusted
	
    self.center = newCenter;
	
	// Update our magnified image to reflect the new touchpoint
	[self setNeedsDisplay];
}

- (void)presentLoupeFromLocation:(CGPoint)location
{
	// calculate transform
	self.alpha = 0;

	CGAffineTransform movedTransform = CGAffineTransformMakeTranslation(location.x - self.center.x, location.y - self.center.y); 
	self.transform = CGAffineTransformScale(movedTransform, 0.25, 0.25);
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:DTDefaultLoupeAnimationDuration];
	
	self.alpha = 1;
	self.transform = CGAffineTransformIdentity;

	[UIView commitAnimations];
}

- (void)dismissLoupeTowardsLocation:(CGPoint)location
{
	// calculate transform
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:DTDefaultLoupeAnimationDuration];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	self.alpha = 0;

	CGAffineTransform movedTransform = CGAffineTransformMakeTranslation(location.x - self.center.x, location.y - self.center.y); 
	self.transform = CGAffineTransformScale(movedTransform, 0.25, 0.25);
	
	[UIView commitAnimations];
}

// Set Type of Loupe to display. We have a type none as the loupe remains initied and can
// just be redisplayed


//- (void)setStyle:(DTLoupeStyle)newType {
//	
//    if (newType == _style)
//        return;
//    
//    BOOL wereAnimationsEnabled = [UIView areAnimationsEnabled];
//    
//    DTLoupeStyle previousType = _style;
//    
//    if (previousType == DTLoupeStyleNone) {
//        // Make sure our Loupe in front most
//        [_targetView bringSubviewToFront:self];
//        
//        // Apply our Start Tranform (scale & position)   
//        [UIView beginAnimations:@"DTLoupeStyle" context:NULL];
//        [UIView setAnimationDuration:0.0]; // We don't want this to take any time
//        [UIView setAnimationsEnabled:NO];
//        CGPoint centerPoint = _touchPoint;
//        self.center = centerPoint;
//		
//        switch (newType) {
//            case DTLoupeStyleNone:
//            default:
//            {
//                self.transform = CGAffineTransformIdentity;
//                break;
//            }
//            case DTLoupeStyleCircle:
//            {
//                self.transform = DTLoupeCircularStartTransform;
//                break;
//            }
//            case DTLoupeStyleRectangle:
//            case DTLoupeStyleRectangleWithArrow:
//            {
//                self.transform = DTLoupeRectangularStartTransform;
//                break;
//            }
//        }
//		
//        self.alpha = 1;
//        [UIView commitAnimations];
//    }
//    
//    // Now animate to the final position & Scale
//    [UIView beginAnimations:@"DTLoupeStyle" context:NULL];
//    [UIView setAnimationBeginsFromCurrentState: (_style == DTLoupeStyleNone)? NO : YES];
//    [UIView setAnimationDuration:DTDefaultLoupeAnimationDuration];
//    [UIView setAnimationsEnabled:YES];
//    
//    _style = newType;
//    
//    if (newType == DTLoupeStyleNone) {
//        /* Shrink and fade the loupe so it's basically invisible */
//        self.transform = DTLoupeDismissedTransform;
//        self.alpha = 0;
//		
//    } else {
//        
//        switch (newType) {
//            case DTLoupeStyleNone:
//            default:
//            {    // Hide our Loupe
//                self.alpha = 0;
//                break;
//            }
//            case DTLoupeStyleCircle:
//            {
//                self.loupeFrameBackgroundImage = [UIImage imageNamed:@"kb-loupe-lo.png"];
//                self.loupeFrameMaskImage = [UIImage imageNamed:@"kb-loupe-mask.png"];
//                self.loupeFrameImage = [UIImage imageNamed:@"kb-loupe-hi.png"];
//				
//                // Size and position
//                CGSize loupeImageSize = [_loupeFrameImage size];
//                loupeFramePosition.size = loupeImageSize;
//				
//                // The difference between the touchpoint and the centre of our circular loupe is
//                // -60, so apply a transform accordingly
//                
//                CGAffineTransform transformZoomed = CGAffineTransformMakeTranslation(0, -60);
//                self.transform = transformZoomed;
//				
//                break;
//            }
//            case DTLoupeStyleRectangle:
//            case DTLoupeStyleRectangleWithArrow:
//            {
//				
//                if(newType == DTLoupeStyleRectangleWithArrow) {
//                    self.loupeFrameBackgroundImage = [UIImage imageNamed:@"kb-magnifier-ranged-lo.png"];
//                } else {
//                    self.loupeFrameBackgroundImage = [UIImage imageNamed:@"kb-magnifier-ranged-lo-stemless.png"];
//                }
//                
//                self.loupeFrameMaskImage = [UIImage imageNamed:@"kb-magnifier-ranged-mask"];
//                self.loupeFrameImage = [UIImage imageNamed:@"kb-magnifier-ranged-hi.png"];
//				
//                // Size and position
//                CGSize loupeImageSize = [_loupeFrameImage size];
//                loupeFramePosition.size = loupeImageSize;
//				
//                CGAffineTransform transformZoomed = CGAffineTransformMakeTranslation(0, -38);
//                self.transform = transformZoomed;
//				
//                break;
//            }
//        }
//		
//        if (previousType == DTLoupeStyleNone)
//            [UIView setAnimationsEnabled:NO];
//        
//        // Position Our Loupe
//        self.bounds = (CGRect){ .origin = { 0,0 }, .size = loupeFramePosition.size };
//        
//        [UIView setAnimationsEnabled:YES];
//    }
//    
//    // Adjust location for new size, touch point, whatever might have changed
//    //[self setTouchPoint:_touchPoint];
//    
//    [UIView commitAnimations];
//    [UIView setAnimationsEnabled:wereAnimationsEnabled];
//    
//}



// Draw our Loupe
- (void)drawRect:(CGRect)rect;
{
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();    
    
    // **** Draw our Loupe's Background Image ****
    [_loupeFrameBackgroundImage drawInRect:rect];
	
    CGContextClipToMask(ctx, rect, _loupeFrameMaskImage.CGImage);
	
    // **** Draw our Target View Magnified and correctly positioned ****
    CGContextSaveGState(ctx);    
    
    // Translate Left & Right, Scale and then shift back to touchPoint
	CGContextTranslateCTM(ctx, self.frame.size.width * 0.5 + _magnifiedImageOffset.x,(self.frame.size.height * 0.5) + _magnifiedImageOffset.y);
	CGContextScaleCTM(ctx, _magnification, _magnification);
	CGContextTranslateCTM(ctx,-_touchPoint.x, -_touchPoint.y);
    
    [_targetView.layer renderInContext:ctx];
    
    CGContextRestoreGState(ctx);
	
    // **** Draw our Loupe's Main Image ****
    [_loupeFrameImage drawInRect:rect];
	
    // Draw Cross Hairs
    if (_drawDebugCrossHairs) {
		[[UIColor redColor] setStroke];
        CGContextStrokeRect(ctx, rect);
        CGContextMoveToPoint(ctx, 0, rect.size.height/2.0f);
        CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height/2.0f);
        CGContextStrokePath(ctx);
        CGContextMoveToPoint(ctx, rect.size.width/2.0f, 0);
        CGContextAddLineToPoint(ctx, rect.size.width/2.0f, rect.size.height);
        CGContextStrokePath(ctx);
    }
	
}



#pragma mark Properties

- (void)setStyle:(DTLoupeStyle)style
{
	[self setImagesForStyle:style];
	
	CGSize size = [DTLoupeView sizeForLoupeStyle:style];
	CGRect bounds = CGRectMake(0, 0, size.width, size.height);
	self.bounds = bounds;
	
	// Different loupes have a different vertical offset for the magnified image (otherwise the touchpoint = equals the centre of maginified image)
	// Circular Loupe is set -4.0f for example
	// With Rectangular Loupe the offset depends on whether clicking the Top or Bottom Text selection Thumb!
	_magnifiedImageOffset = [DTLoupeView magnifiedImageOffsetForStyle:style];
	
	[self setNeedsDisplay];
}

@synthesize loupeFrameImage = _loupeFrameImage;
@synthesize loupeFrameBackgroundImage = _loupeFrameBackgroundImage;
@synthesize loupeFrameMaskImage = _loupeFrameMaskImage;

@synthesize touchPoint = _touchPoint;
@synthesize style = _style;
@synthesize magnification = _magnification;
@synthesize targetView = _targetView;
@synthesize magnifiedImageOffset = _magnifiedImageOffset;

@synthesize drawDebugCrossHairs = _drawDebugCrossHairs;

@end
