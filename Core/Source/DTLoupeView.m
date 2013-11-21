//
//  DTLoupeView.m
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import "DTLoupeView.h"
#import <QuartzCore/QuartzCore.h>

#define DTLoupeDefaultMagnification         1.20     // Match Apple's Magnification
#define DTLoupeAnimationDuration			0.15     // Match Apple's Duration

CGAffineTransform CGAffineTransformAndScaleMake(CGFloat sx, CGFloat sy, CGFloat tx, CGFloat ty);

NSString * const DTLoupeDidHide = @"DTLoupeDidHide";

@interface DTLoupeView ()

+ (CGSize)sizeForLoupeStyle:(DTLoupeStyle)style;
+ (CGPoint)offsetFromCenterForLoupeStyle:(DTLoupeStyle)style;
- (UIView *)rootViewForView:(UIView *)view;

+ (UIWindow *)loupeWindow;

@property (nonatomic, retain) UIImage *loupeFrameImage;
@property (nonatomic, retain) UIImage *loupeFrameBackgroundImage;
@property (nonatomic, retain) UIImage *loupeFrameMaskImage;

@end

@implementation DTLoupeView
{
	CALayer *_loupeFrameBackgroundImageLayer;
	CALayer *_loupeContentsLayer;
	CALayer *_loupeContentsMaskLayer;
	CALayer *_loupeFrameImageLayer;
	
	DTLoupeStyle _style;                     // Type of Loupe; None, Circle, Rectangle, Rectangle With Arrow
	
	CGPoint _touchPoint;                // The point at which to display (in our target view's bounds coordinates)
	CGSize _touchPointOffset;
	CGFloat         _magnification;             // How much to magnify the view
	CGPoint         _magnifiedImageOffset;          // Offset of vertical position of magnified image from centre of Loupe NB Touchpoint is normally centered in Loupe
	
	__WEAK UIView *_targetView;               // View to Magnify
	__WEAK UIView  *_targetRootView;					// the actually used view, because this has orientation changes applied
	
	// A Loupe/Magnifier is based on 3 images. Background, Mask & Main
	UIImage         *_loupeFrameImage;
	UIImage         *_loupeFrameBackgroundImage;
	UIImage         *_loupeFrameMaskImage;
	
	BOOL _seeThroughMode; // look-through-mode, used while scrolling
	
	BOOL _drawDebugCrossHairs;       // Draws cross hairs for debugging
}


+ (DTLoupeView *)sharedLoupe
{
	static dispatch_once_t onceToken;
	static DTLoupeView *_sharedInstance = nil;
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[DTLoupeView alloc] init];
	});
	
	return _sharedInstance;
}

+ (UIWindow *)loupeWindow
{
	static dispatch_once_t onceToken;
	static UIWindow *_loupeWindow = nil;
	
	dispatch_once(&onceToken, ^{
		// find application main Window and attach it there
		UIWindow *mainWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
		[mainWindow addSubview:_loupeWindow];
		
		// we always adjust the loupeWindow to be identical in frame/transform to target root view
		_loupeWindow = [[UIWindow alloc] initWithFrame:mainWindow.bounds];
		_loupeWindow.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_loupeWindow.hidden = NO;
		_loupeWindow.userInteractionEnabled = NO;
		
		
		// keep the main rootViewController responsible for the status bar content mode
		_loupeWindow.rootViewController = mainWindow.rootViewController;
	});
	
	return _loupeWindow;
}

- (id)init
{
	self = [super initWithFrame:CGRectZero];
	if (self)
	{
		// make sure that resource bundle is present
		NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"DTLoupe" ofType:@"bundle"];
		
		if (!resourceBundlePath)
		{
			NSLog(@"DTLoupe.bundle is missing from app bundle. Please make sure that you include it in your app's resources");
		};
		
		self.contentMode = UIViewContentModeCenter;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		
		_magnification = DTLoupeDefaultMagnification;
		self.alpha = 0;
		
		// this loupe view has its own window
		[[DTLoupeView loupeWindow] addSubview:self];
		
		// --- setup up layers ---
		
        CGFloat scale = [UIScreen mainScreen].scale;
        
		// layer with lo image of loupe
		_loupeFrameBackgroundImageLayer = [CALayer layer];
        _loupeFrameBackgroundImageLayer.contentsScale = scale;
		[self.layer addSublayer:_loupeFrameBackgroundImageLayer];
		
		// maks for the loupe contents layer
		_loupeContentsMaskLayer = [CALayer layer];
		_loupeContentsMaskLayer.transform = CATransform3DMakeScale(1.0f, -1.0f, 1.0f);
        _loupeContentsMaskLayer.contentsScale = scale;

		// layer with contents of the loupe
		_loupeContentsLayer = [CALayer layer];
		_loupeContentsLayer.delegate = self;
		_loupeContentsLayer.mask = _loupeContentsMaskLayer;
        _loupeContentsLayer.contentsScale = scale;
		[self.layer addSublayer:_loupeContentsLayer];
		
		// layer with hi image of loupe
		_loupeFrameImageLayer = [CALayer layer];
        _loupeFrameImageLayer.contentsScale = scale;
		[self.layer addSublayer:_loupeFrameImageLayer];
	}
	
	return self;
}

- (void)removeFromSuperview
{
	NSLog(@"Warning: %s should never be called", __PRETTY_FUNCTION__);
}

- (void)addSubview:(UIView *)view
{
	NSLog(@"Warning: %s should never be called", __PRETTY_FUNCTION__);
}

#pragma mark Utilities

// there is a difference between concatenating and scaling an existing transform
CGAffineTransform CGAffineTransformAndScaleMake(CGFloat sx, CGFloat sy, CGFloat tx, CGFloat ty)
{
	CGAffineTransform transform = CGAffineTransformMakeTranslation(tx, ty);
	return CGAffineTransformScale(transform, sx, sy);
}

// round up image sizes so that setting center does not cause non-integer origin of view
+ (CGSize)sizeForLoupeStyle:(DTLoupeStyle)style;
{
	switch (style)
	{
		case DTLoupeStyleCircle:
			return CGSizeMake(128.0, 128.0);
			
		case DTLoupeStyleRectangle:
			return CGSizeMake(142.0, 56.0);
			
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
			return CGPointMake(0, -30.0);
			
		case DTLoupeStyleRectangleWithArrow:
			return CGPointMake(0, -30.0);
			
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
			return CGPointMake(0, -18.0);
		}
			
		case DTLoupeStyleRectangleWithArrow:
		{
			return CGPointMake(0, -18.0);
		}
			
		default:
			return CGPointZero;
	}
}

- (UIView *)rootViewForView:(UIView *)view
{
	while (view.superview != view.window)
	{
		view = view.superview;
	}
	
	return view;
}

// keep rotation and transform of base view in sync with target root view
- (void)adjustBaseViewIfNecessary
{
	UIWindow *loupeWindow = [DTLoupeView loupeWindow];
	
	NSAssert(self.superview, @"Sombody removed DTLoupeView from superview!!");
	
	BOOL sameFrame = (CGRectEqualToRect(loupeWindow.frame, _targetRootView.frame));
	BOOL sameTransform = (CGAffineTransformEqualToTransform(loupeWindow.transform, _targetRootView.transform));
	
	if (!(sameFrame && sameTransform))
	{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
		// looks like the device was rotated
		loupeWindow.transform = _targetRootView.transform;
		loupeWindow.frame = _targetRootView.frame;
        [CATransaction commit];
	}
}

- (void)setImagesForStyle:(DTLoupeStyle)style
{
	switch (style)
	{
		case DTLoupeStyleCircle:
		{
			self.loupeFrameBackgroundImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-loupe-lo.png"];
			self.loupeFrameMaskImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-loupe-mask.png"];
			self.loupeFrameImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-loupe-hi.png"];
			
			break;
		}
		case DTLoupeStyleRectangle:
		{
			self.loupeFrameBackgroundImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-magnifier-ranged-lo-stemless.png"];
			self.loupeFrameMaskImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-magnifier-ranged-mask.png"];
			self.loupeFrameImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-magnifier-ranged-hi.png"];
			
			break;
		}
			
		case DTLoupeStyleRectangleWithArrow:
		{
			self.loupeFrameBackgroundImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-magnifier-ranged-lo.png"];
			self.loupeFrameMaskImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-magnifier-ranged-mask.png"];
			self.loupeFrameImage = [UIImage imageNamed:@"DTLoupe.bundle/kb-magnifier-ranged-hi.png"];
			
			break;
		}
	}
	
	_loupeFrameBackgroundImageLayer.contents = (__bridge id)self.loupeFrameBackgroundImage.CGImage;
	_loupeContentsMaskLayer.contents = (__bridge id)self.loupeFrameMaskImage.CGImage;
	_loupeFrameImageLayer.contents = (__bridge id)self.loupeFrameImage.CGImage;
}

#pragma mark Interactivity
- (void)setTouchPoint:(CGPoint)touchPoint
{
	NSAssert(_targetView, @"Cannot set loupe touchPoint without targetView set");
	
	[self adjustBaseViewIfNecessary];
	
	// Set touchPoint as user moves around screen
	_touchPoint = touchPoint;
	
    CGPoint pointInWindow = [_targetView.window convertPoint:_touchPoint fromView:_targetView];
	CGPoint convertedLocation = [[DTLoupeView loupeWindow] convertPoint:pointInWindow fromWindow:_targetView.window];
	
    // additional NAN check for safety
    if (isnan(convertedLocation.x) || (isnan(convertedLocation.y)))
    {
        return;
    }
    
	CGPoint newCenter = convertedLocation;
	CGPoint offsetFromTouchPoint = [DTLoupeView offsetFromCenterForLoupeStyle:_style];
	
	newCenter.x += offsetFromTouchPoint.x;
	newCenter.y += offsetFromTouchPoint.y;
	
	// We do it here so that the centre of displayed "magnified image"
	// captured in drawRect doesn't need to be adjusted
	
	CGRect frame = self.frame;
	frame.origin.x = roundf(newCenter.x - frame.size.width/2.0f);
	frame.origin.y = roundf(newCenter.y - frame.size.height/2.0f);
	
	if (!CGRectEqualToRect(self.frame, frame))
	{
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		
		self.frame = frame;
		
		// Update our magnified image to reflect the new touchpoint
		[_loupeContentsLayer setNeedsDisplay];
		
		[CATransaction commit];
	}
}

- (void)presentLoupeFromLocation:(CGPoint)location
{
	NSAssert(_targetView, @"Cannot present loupe without targetView set");
	
	[self adjustBaseViewIfNecessary];
	
	// circular loupe does not fade
	self.alpha = (_style == DTLoupeStyleCircle)?1.0:0.0;
	
	// calculate transform
	CGPoint convertedLocation = [_targetView convertPoint:location toView:[DTLoupeView loupeWindow]];
	CGPoint offset = CGPointMake(convertedLocation.x - self.center.x, convertedLocation.y - self.center.y);
	self.transform = CGAffineTransformAndScaleMake(0.25, 0.25, offset.x, offset.y);
	
	[UIView animateWithDuration:DTLoupeAnimationDuration
								 delay:0
							  options:UIViewAnimationCurveEaseOut
						  animations:^{
							  self.alpha = 1.0;
							  self.transform = CGAffineTransformIdentity;					 }
						  completion:^(BOOL finished) {
						  }];
}

- (void)dismissLoupeTowardsLocation:(CGPoint)location
{
	[UIView animateWithDuration:DTLoupeAnimationDuration
								 delay:0
							  options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationCurveEaseOut
						  animations:^{
							  // circular loupe does not fade
							  self.alpha = (_style == DTLoupeStyleCircle)?1.0:0.0;
							  
							  // calculate transform
							  CGPoint convertedLocation = [_targetView convertPoint:location toView:self.superview];
							  CGPoint offset = CGPointMake(convertedLocation.x - self.center.x, convertedLocation.y - self.center.y);
							  self.transform = CGAffineTransformAndScaleMake(0.05, 0.05, offset.x, offset.y);
						  }
						  completion:^(BOOL finished) {
							  // hide it completely
							  self.alpha = 0;
							  
							  // reset transform to get correct offset on next present
							  self.transform = CGAffineTransformIdentity;
							  
							  // reset images so that we don't get old contents flashing in next present.
							  _loupeFrameBackgroundImageLayer.contents = nil;
							  _loupeContentsMaskLayer.contents = nil;
							  _loupeContentsLayer.contents = nil;
							  _loupeFrameImageLayer.contents = nil;
							  
							  // keep it in view hierarchy
							  
							  [[NSNotificationCenter defaultCenter] postNotificationName:DTLoupeDidHide object:self];
						  }];
}

- (BOOL)isShowing
{
	return (self.superview != nil && self.alpha>0);
}

#pragma mark - CALayerDelegate

// only used for the content layer, draws the view hierarchy of the target root view
- (void)displayLayer:(CALayer *)layer
{
    if (_seeThroughMode || layer != _loupeContentsLayer)
    {
        return;
    }
	
	CGSize size = layer.bounds.size;
	size.width *= layer.contentsScale;
	size.height *= layer.contentsScale;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
	
	CGAffineTransform transform = CGAffineTransformMake(layer.contentsScale, 0, 0, -layer.contentsScale, 0, layer.bounds.size.height * layer.contentsScale);
	CGContextConcatCTM(ctx, transform);
	
    // **** Draw our Target View Magnified and correctly positioned ****
    // move touchpoint by offset
    CGPoint offsetTouchPoint = _touchPoint;
    offsetTouchPoint.x += _touchPointOffset.width;
    offsetTouchPoint.y += _touchPointOffset.height;
    
    CGPoint convertedLocation = [_targetView convertPoint:offsetTouchPoint toView:_targetRootView];
    
    // Translate Right & Down, Scale and then shift back to touchPoint
    CGContextTranslateCTM(ctx, self.frame.size.width * 0.5 + _magnifiedImageOffset.x,(self.frame.size.height * 0.5) + _magnifiedImageOffset.y);
    CGContextScaleCTM(ctx, _magnification, _magnification);
    
    CGContextTranslateCTM(ctx,-convertedLocation.x, -convertedLocation.y);
    
    // the loupe is not part of the rendered tree, so we don't need to hide it
    [_targetRootView.layer renderInContext:ctx];
	
	CGImageRef image = CGBitmapContextCreateImage(ctx);
	layer.contents = CFBridgingRelease(image);
	
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(ctx);
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	if (layer!=self.layer)
	{
		return;
	}
	
	CGRect bounds = self.bounds;
	
	_loupeFrameBackgroundImageLayer.frame = bounds;
	_loupeContentsMaskLayer.frame = bounds;
	_loupeContentsLayer.frame = bounds;
	_loupeFrameImageLayer.frame = bounds;
}

#pragma mark - Properties
- (void)setTargetView:(UIView *)targetView
{
	if (targetView != _targetView)
	{
		_targetView = targetView;
		_targetRootView = [self rootViewForView:_targetView];
	}
}

- (void)setStyle:(DTLoupeStyle)style
{
	_style = style;
	
	// avoid frame animation on style change
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	CGSize size = [DTLoupeView sizeForLoupeStyle:style];
	CGRect bounds = CGRectMake(0, 0, size.width, size.height);
	self.bounds = bounds;
	
	_loupeFrameBackgroundImageLayer.frame = bounds;
	_loupeContentsMaskLayer.frame = bounds;
	_loupeContentsLayer.frame = bounds;
	_loupeFrameImageLayer.frame = bounds;
	
	[self setImagesForStyle:_style];
	
	[CATransaction commit];
	
	// Different loupes have a different vertical offset for the magnified image (otherwise the touchpoint = equals the centre of maginified image)
	// Circular Loupe is set -4.0f for example
	// With Rectangular Loupe the offset depends on whether clicking the Top or Bottom Text selection Thumb!
	_magnifiedImageOffset = [DTLoupeView magnifiedImageOffsetForStyle:style];
	
	_touchPointOffset = CGSizeZero;
	
	[_loupeContentsLayer setNeedsDisplay];
}

- (void)setSeeThroughMode:(BOOL)seeThroughMode
{
	if (_seeThroughMode != seeThroughMode)
	{
		_seeThroughMode = seeThroughMode;
		
		if (_seeThroughMode)
		{
			_loupeFrameBackgroundImageLayer.opacity = 0.7;
			_loupeContentsLayer.hidden = YES;
		}
		else
		{
			_loupeFrameBackgroundImageLayer.opacity = 1.0;
			_loupeContentsLayer.hidden = NO;
		}
		
		[_loupeContentsLayer setNeedsDisplay];
	}
}

- (void)setMagnification:(CGFloat)magnification
{
	if (_magnification != magnification)
	{
		_magnification = magnification;
		[_loupeContentsLayer setNeedsDisplay];
	}
}

@synthesize loupeFrameImage = _loupeFrameImage;
@synthesize loupeFrameBackgroundImage = _loupeFrameBackgroundImage;
@synthesize loupeFrameMaskImage = _loupeFrameMaskImage;

@synthesize touchPoint = _touchPoint;
@synthesize touchPointOffset = _touchPointOffset;
@synthesize style = _style;
@synthesize magnification = _magnification;
@synthesize targetView = _targetView;
@synthesize magnifiedImageOffset = _magnifiedImageOffset;

@synthesize seeThroughMode = _seeThroughMode;

@end
