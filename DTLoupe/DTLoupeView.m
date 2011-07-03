//
//  DTLoupeView.m
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import "DTLoupeView.h"
#import <QuartzCore/QuartzCore.h>

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

@synthesize touchPoint = _touchPoint;
@synthesize style = _style;
@synthesize magnification = _magnification;
@synthesize targetView = _targetView;
@synthesize loupeImageOffset = _loupeImageOffset;

@synthesize drawDebugCrossHairs = _drawDebugCrossHairs;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = nil;
        self.clearsContextBeforeDrawing = YES;
        self.contentMode = UIViewContentModeCenter;
        
        _style = DTLoupeOverlayNone;
        _touchPoint = (CGPoint){ 0, 0 };
        _magnification = DTDefaultLoupeMagnification;
        _loupeImageOffset = 0.0;
        
        self.alpha = 0;

    }
    return self;
}

// Set TouchPoint as user moves around screen
- (void)setTouchPoint:(CGPoint)touchPoint;
{
    _touchPoint = touchPoint;
    CGPoint indicatedPoint =_touchPoint;
    
    // If we have attached our Loupe to the UIWindow, we need to convert the 
    // touchpoint to targectView's Coordinates
    
    // We do it here so that the centre of displayed "magnified image" 
    // captured in drawRect doesn't need to be adjusted

    if ([self.superview isKindOfClass:[UIWindow class]]) {
        indicatedPoint = [_targetView.window convertPoint:touchPoint fromView:_targetView];
	}
    
    self.center = indicatedPoint;

    if (_style != DTLoupeOverlayNone) {

        // When dismissing Loupe we do not update drawRect as do not want 
        // to update the magnified image, but just let scale "away" with the Loupe

        // Update our magnified image to reflect the new touchpoint
        [self setNeedsDisplay];
    }        
}

// Set Type of Loupe to display. We have a type none as the loupe remains initied and can
// just be redisplayed
- (void)setStyle:(DTLoupeStyle)newType {

    if (newType == _style)
        return;
    
    BOOL wereAnimationsEnabled = [UIView areAnimationsEnabled];
    
    DTLoupeStyle previousType = _style;
    
    if (previousType == DTLoupeOverlayNone) {
        // Make sure our Loupe in front most
        [_targetView bringSubviewToFront:self];
        
        // Apply our Start Tranform (scale & position)   
        [UIView beginAnimations:@"DTLoupeOverlay" context:NULL];
        [UIView setAnimationDuration:0.0]; // We don't want this to take any time
        [UIView setAnimationsEnabled:NO];
        CGPoint centerPoint = _touchPoint;
        self.center = centerPoint;

        switch (newType) {
            case DTLoupeOverlayNone:
            default:
            {
                self.transform = CGAffineTransformIdentity;
                break;
            }
            case DTLoupeOverlayCircle:
            {
                self.transform = DTLoupeCircularStartTransform;
                break;
            }
            case DTLoupeOverlayRectangle:
            case DTLoupeOverlayRectangleWithArrow:
            {
                self.transform = DTLoupeRectangularStartTransform;
                break;
            }
        }

        self.alpha = 1;
        [UIView commitAnimations];
    }
    
    // Now animate to the final position & Scale
    [UIView beginAnimations:@"DTLoupeOverlay" context:NULL];
    [UIView setAnimationBeginsFromCurrentState: (_style == DTLoupeOverlayNone)? NO : YES];
    [UIView setAnimationDuration:DTDefaultLoupeAnimationDuration];
    [UIView setAnimationsEnabled:YES];
    
    _style = newType;
    
    if (newType == DTLoupeOverlayNone) {
        /* Shrink and fade the loupe so it's basically invisible */
        self.transform = DTLoupeDismissedTransform;
        self.alpha = 0;

    } else {
        
        switch (newType) {
            case DTLoupeOverlayNone:
            default:
            {    // Hide our Loupe
                self.alpha = 0;
                break;
            }
            case DTLoupeOverlayCircle:
            {
                loupeFrameBackgroundImage = [[UIImage imageNamed:@"kb-loupe-lo.png"] retain];
                loupeFrameMaskImage = [[UIImage imageNamed:@"kb-loupe-mask.png"] retain];
                loupeFrameImage = [[UIImage imageNamed:@"kb-loupe-hi.png"] retain];
                                
                // Size and position
                CGSize loupeImageSize = [loupeFrameImage size];
                loupeFramePosition.size = loupeImageSize;

                // The difference between the touchpoint and the centre of our circular loupe is
                // -60, so apply a transform accordingly
                
                CGAffineTransform transformZoomed = CGAffineTransformMakeTranslation(0, -60);
                self.transform = transformZoomed;

                break;
            }
            case DTLoupeOverlayRectangle:
            case DTLoupeOverlayRectangleWithArrow:
            {

                if(newType == DTLoupeOverlayRectangleWithArrow) {
                    loupeFrameBackgroundImage = [[UIImage imageNamed:@"kb-magnifier-ranged-lo.png"] retain];
                } else {
                    loupeFrameBackgroundImage = [[UIImage imageNamed:@"kb-magnifier-ranged-lo-stemless.png"] retain];
                }
                
                loupeFrameMaskImage = [[UIImage imageNamed:@"kb-magnifier-ranged-mask"] retain];
                loupeFrameImage = [[UIImage imageNamed:@"kb-magnifier-ranged-hi.png"] retain];

                // Size and position
                CGSize loupeImageSize = [loupeFrameImage size];
                loupeFramePosition.size = loupeImageSize;
                                
                CGAffineTransform transformZoomed = CGAffineTransformMakeTranslation(0, -38);
                self.transform = transformZoomed;

                break;
            }
        }
                
        if (previousType == DTLoupeOverlayNone)
            [UIView setAnimationsEnabled:NO];
        
        // Position Our Loupe
        self.bounds = (CGRect){ .origin = { 0,0 }, .size = loupeFramePosition.size };
        
        [UIView setAnimationsEnabled:YES];
    }
    
    // Adjust location for new size, touch point, whatever might have changed
    [self setTouchPoint:_touchPoint];
    
    [UIView commitAnimations];
    [UIView setAnimationsEnabled:wereAnimationsEnabled];
    
}

// Draw our Loupe
- (void)drawRect:(CGRect)rect;
{
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();    
    
    // **** Draw our Loupe's Background Image ****
    [loupeFrameBackgroundImage drawInRect:rect];

    CGContextClipToMask(ctx, rect, loupeFrameMaskImage.CGImage);

    // **** Draw our Target View Magnified and correctly positioned ****
    CGContextSaveGState(ctx);    
    
    // Translate Left & Right, Scale and then shift back to touchPoint
	CGContextTranslateCTM(ctx, self.frame.size.width * 0.5,(self.frame.size.height * 0.5) + _loupeImageOffset);
	CGContextScaleCTM(ctx, _magnification, _magnification);
	CGContextTranslateCTM(ctx,-_touchPoint.x, -_touchPoint.y);
    
    [_targetView.layer renderInContext:ctx];
    
    CGContextRestoreGState(ctx);

    // **** Draw our Loupe's Main Image ****
    [loupeFrameImage drawInRect:rect];

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

- (void)dealloc
{
    [super dealloc];
}

@end
