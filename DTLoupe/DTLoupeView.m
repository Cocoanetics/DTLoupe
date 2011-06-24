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

#define DTLoupeDismissedTransform (CGAffineTransform){ 0.0625, 0, 0, 0.25, 0, 0 };

@synthesize touchPoint = _touchPoint;
@synthesize style = _style;
@synthesize magnification = _magnification;
@synthesize targetView = _targetView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = nil;
        self.clearsContextBeforeDrawing = YES;
        self.contentMode = UIViewContentModeScaleAspectFit;
        
        _style = DTLoupeOverlayNone;
        _touchPoint = (CGPoint){ 0, 0 };
        _magnification = 1.25;
        
        self.alpha = 0;
        self.transform = DTLoupeDismissedTransform;
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
    
    if (_style == DTLoupeOverlayNone) {

        CGPoint centerPoint = touchPoint;
        self.center = centerPoint;

    } else {
        CGRect newFrame;
        
        if (_style == DTLoupeOverlayRectangle)
            loupeFramePosition.origin.x = loupeTouchPoint.x;
        
        newFrame.origin.x = round(indicatedPoint.x - loupeFramePosition.origin.x);
        
        // The very bottom of the Loupe should appear at our touchpoint
        newFrame.origin.y = round(indicatedPoint.y - loupeFramePosition.size.height);
        
        newFrame.size = loupeFramePosition.size;
        
        self.frame = newFrame;
    }
        
    // Need to redisplay because our contents depend on the touch point
    [self setNeedsDisplay];
}

// Set Type of Loupe to display. We have a type none as the loupe remains initied and can
// just be redisplayed
- (void)setStyle:(DTLoupeStyle)newType {

    if (newType == _style)
        return;
    
    [self willChangeValueForKey:@"style"];  // IS THIS REQUIRED?????
    
    Class animatorClass = [self class];
    BOOL wereAnimationsEnabled = [animatorClass areAnimationsEnabled];
    
    DTLoupeStyle previousType = _style;
    
    if (previousType == DTLoupeOverlayNone) {
        // Make sure our Loupe in front most
        [_targetView bringSubviewToFront:self];
        
        // And make sure it animates from the current location, instead of the previous location
        [animatorClass beginAnimations:@"DTLoupeOverlay" context:NULL];
        [animatorClass setAnimationsEnabled:NO];
        CGPoint centerPoint = _touchPoint;
        self.center = centerPoint;
        self.transform = DTLoupeDismissedTransform;
        self.alpha = 1;
        [animatorClass commitAnimations];
    }
    
    [animatorClass beginAnimations:@"DTLoupeOverlay" context:NULL];
    [animatorClass setAnimationBeginsFromCurrentState: (_style == DTLoupeOverlayNone)? NO : YES];
    [animatorClass setAnimationsEnabled:YES];
    
    _style = newType;
    
    if (newType == DTLoupeOverlayNone) {
        /* Shrink and fade the loupe */
        self.transform = DTLoupeDismissedTransform;
        self.alpha = 0;

    } else {
        
        if (loupeFrameImage) {
            [loupeFrameImage release];
            loupeFrameImage = nil;
        }

        // Reset any transform applied when we dismissed it
        self.transform = (CGAffineTransform){ 1, 0, 0, 1, 0, 0 };
        
        switch (newType) {
            case DTLoupeOverlayNone:
            default:
            {    // Hide our Loupe
                loupeFramePosition.origin.x = 0;
                loupeFramePosition.origin.y = 0;
                loupeFramePosition.size.width = 0;
                loupeFramePosition.size.height = 0;
                loupeTouchPoint.x = 0;
                loupeTouchPoint.y = 0;
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
                loupeFramePosition.origin.x = loupeImageSize.width / 2;
                loupeFramePosition.origin.y = loupeImageSize.height;  // + 30;
                loupeTouchPoint.x = loupeImageSize.width / 2;
                loupeTouchPoint.y = loupeImageSize.height / 2;
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

                CGSize loupeImageSize;
                loupeImageSize = [loupeFrameImage size];

//                CGRect contour = (CGRect){ {RectLoupeSideInset, RectLoupeTopInset},
//                    { loupeImageSize.width - 2 * RectLoupeSideInset,
//                        loupeImageSize.height - (RectLoupeTopInset + RectLoupeBottomInset) } };
//                                
                CGRect contour = CGRectMake(0, 0, loupeImageSize.width, loupeImageSize.height);

                loupeTouchPoint.x = CGRectGetMidX(contour);
                loupeTouchPoint.y = CGRectGetMidY(contour);
                loupeFramePosition.size = loupeImageSize;
                loupeFramePosition.origin.x = loupeTouchPoint.x;
                loupeFramePosition.origin.y = loupeImageSize.height + 20;

                break;
            }
        }
        
        self.alpha = 1;
        
        if (previousType == DTLoupeOverlayNone)
            [animatorClass setAnimationsEnabled:NO];
        
        // Position Our Loupe
        self.bounds = (CGRect){ .origin = { 0,0 }, .size = loupeFramePosition.size };
        
        [animatorClass setAnimationsEnabled:YES];
    }
    
    // Adjust location for new size, touch point, whatever might have changed
    [self setTouchPoint:_touchPoint];
    
    [animatorClass commitAnimations];
    [animatorClass setAnimationsEnabled:wereAnimationsEnabled];
    
    [self didChangeValueForKey:@"style"]; // IS THIS REQUIRED?????

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
	CGContextTranslateCTM(ctx, self.frame.size.width * 0.5,self.frame.size.height * 0.5);
	CGContextScaleCTM(ctx, _magnification, _magnification);
	CGContextTranslateCTM(ctx,-_touchPoint.x, -_touchPoint.y);
    
    [_targetView.layer renderInContext:ctx];
    
    CGContextRestoreGState(ctx);

    // **** Draw our Loupe's Main Image ****
    [loupeFrameImage drawInRect:rect];

//    Draw Debugging
//    [[UIColor redColor] setStroke];
//    CGContextStrokeRect(ctx, rect);
//    CGContextMoveToPoint(ctx, 0, rect.size.height/2.0f);
//    CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height/2.0f);
//    CGContextStrokePath(ctx);

}

- (void)dealloc
{
    [super dealloc];
}

@end
