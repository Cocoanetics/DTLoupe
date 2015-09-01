//
//  DTLoupeView.m
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2013 Drobnik KG. All rights reserved.
//

#import "DTLoupeView.h"
#import "DTLoupeLayerDelegate.h"
#import <QuartzCore/QuartzCore.h>
#include <tgmath.h>

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
@property (nonatomic, strong) DTLoupeLayerDelegate *layerDelegate;

@end

@implementation DTLoupeView
{
	CALayer *_loupeFrameBackgroundImageLayer;
	CALayer *_loupeContentsLayer;
	CALayer *_loupeContentsMaskLayer;
	CALayer *_loupeFrameImageLayer;
	
	// Type of Loupe; None, Circle, Rectangle, Rectangle With Arrow
	DTLoupeStyle _style;
	
	// The point at which to display (in our target view's bounds coordinates)
	CGPoint _touchPoint;
	CGSize _touchPointOffset;
	
	// How much to magnify the view
	CGFloat _magnification;
	
	// Offset of vertical position of magnified image from centre of Loupe NB Touchpoint is normally centered in Loupe
	CGPoint _magnifiedImageOffset;
	
	// View to Magnify
	__WEAK UIView *_targetView;
	
	// the actually used view, because this has orientation changes applied
	__WEAK UIView  *_targetRootView;
	
	// A Loupe/Magnifier is based on 3 images. Background, Mask & Main
	UIImage *_loupeFrameImage;
	UIImage *_loupeFrameBackgroundImage;
	UIImage *_loupeFrameMaskImage;
	
	// look-through-mode, used while scrolling
	BOOL _seeThroughMode;
	
	// Draws cross hairs for debugging
	BOOL _drawDebugCrossHairs;
	
	// the resource bundle
	NSBundle *_resourceBundle;
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
		
		// we always adjust the loupeWindow to be identical in frame/transform to target root view
		_loupeWindow = [[UIWindow alloc] initWithFrame:mainWindow.bounds];
		_loupeWindow.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_loupeWindow.hidden = NO;
		_loupeWindow.userInteractionEnabled = NO;
		_loupeWindow.windowLevel = UIWindowLevelAlert;
	});
	
	return _loupeWindow;
}

- (id)init
{
	self = [super initWithFrame:CGRectZero];
	
	if (self)
	{
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
		_layerDelegate = [[DTLoupeLayerDelegate alloc] initWithLoupeView:self];
		_loupeContentsLayer.delegate = _layerDelegate;
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

- (UIInterfaceOrientation)_inferredInterfaceOrientation
{
	// try status bar orientation first, should work
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	if (orientation != UIInterfaceOrientationUnknown)
	{
		return orientation;
	}
	
	// try interface orientation of root view controller next
	// note: going to be removed in iOS 9
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
	if ([_targetView.window.rootViewController respondsToSelector:@selector(interfaceOrientation)])
	{
		orientation = _targetView.window.rootViewController.interfaceOrientation;
		
		if (orientation != UIInterfaceOrientationUnknown)
		{
			return orientation;
		}
	}
#endif
	
	// last resort, get it from device, might fail for face up and face down
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	
	if (_targetView.window.frame.size.width > _targetView.window.frame.size.height)
	{
		// landscape
		
		if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
		{
			return UIInterfaceOrientationLandscapeRight;
		}
		else
		{
			return UIInterfaceOrientationLandscapeLeft;
		}
	}
	else
	{
		// portrait
		
		if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
		{
			return UIInterfaceOrientationPortraitUpsideDown;
		}
	}
	
	// all other cases assume portrait
	return UIInterfaceOrientationPortrait;
}

- (CGAffineTransform)_loupeWindowTransform
{
	// beginning with iOS 8 we need to determine the rotation ourselves
	if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)
	{
		return _targetRootView.transform;
	}
	
	UIInterfaceOrientation orientation = [self _inferredInterfaceOrientation];
	
	// the CGAffineTransformMakeRotation would return weird values from rotating, so we return exact values
	switch (orientation)
	{
		case UIInterfaceOrientationLandscapeLeft:
		{
			return CGAffineTransformMake(0, -1, 1, 0, 0, 0); // CGAffineTransformMakeRotation(-M_PI_2);
		}
			
		case UIInterfaceOrientationLandscapeRight:
		{
			return CGAffineTransformMake(0, 1, -1, 0, 0, 0); // CGAffineTransformMakeRotation(M_PI_2);
		}
			
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			return CGAffineTransformMake(-1, 0, 0, -1, 0, 0); // CGAffineTransformMakeRotation(M_PI);
		}
			
		default:
		case UIInterfaceOrientationPortrait:
		{
			return CGAffineTransformIdentity;
		}
	}
}


// keep rotation and transform of base view in sync with target root view
- (void)adjustBaseViewIfNecessary
{
	UIWindow *loupeWindow = [DTLoupeView loupeWindow];
	
	NSAssert(self.superview, @"Sombody removed DTLoupeView from superview!!");
	
	CGAffineTransform transform = [self _loupeWindowTransform];
	
	BOOL sameFrame = (CGRectEqualToRect(loupeWindow.frame, _targetRootView.frame));
	BOOL sameTransform = (CGAffineTransformEqualToTransform(loupeWindow.transform, transform));
	
	if (!(sameFrame && sameTransform))
	{
		// looks like the device was rotated
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		
		loupeWindow.transform = transform;
		loupeWindow.frame = _targetRootView.frame;
		
		[CATransaction commit];
	}
}

- (NSBundle *)_resourceBundle
{
	if (!_resourceBundle)
	{
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSString *resourceBundlePath = [bundle pathForResource:@"DTLoupe" ofType:@"bundle"];
		
		if (!resourceBundlePath)
		{
			// try to find it in main bundle instead
			bundle = [NSBundle mainBundle];
			resourceBundlePath = [bundle pathForResource:@"DTLoupe" ofType:@"bundle"];
		}
		
		NSAssert(resourceBundlePath, @"DTLoupe.bundle is missing from app bundle. Please make sure that you include it in your app's resources or embed the DTRichTextEditor.framework");
		
		_resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
	}
	
	return _resourceBundle;
}

- (UIImage *)_imageNamedFromResourceBundle:(NSString *)name
{
	NSBundle *resourceBundle = [self _resourceBundle];

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
	// this method works >= iOS 8 and is the preferred way to get images from bundles
	UIImage *image = [UIImage imageNamed:name inBundle:resourceBundle compatibleWithTraitCollection:nil];
#else
	// classic method to get images from bundles
	NSString *imagePath = [resourceBundle pathForResource:name ofType:@"png"];
	UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
#endif
	
	return image;
}

- (void)setImagesForStyle:(DTLoupeStyle)style
{
	switch (style)
	{
		case DTLoupeStyleCircle:
		{
			self.loupeFrameBackgroundImage = [self _imageNamedFromResourceBundle:@"kb-loupe-lo"];
			self.loupeFrameMaskImage = [self _imageNamedFromResourceBundle:@"kb-loupe-mask"];
			self.loupeFrameImage = [self _imageNamedFromResourceBundle:@"kb-loupe-hi"];
			
			break;
		}
		case DTLoupeStyleRectangle:
		{
			self.loupeFrameBackgroundImage = [self _imageNamedFromResourceBundle:@"kb-magnifier-ranged-lo-stemless"];
			self.loupeFrameMaskImage = [self _imageNamedFromResourceBundle:@"kb-magnifier-ranged-mask"];
			self.loupeFrameImage = [self _imageNamedFromResourceBundle:@"kb-magnifier-ranged-hi"];
			
			break;
		}
			
		case DTLoupeStyleRectangleWithArrow:
		{
			self.loupeFrameBackgroundImage = [self _imageNamedFromResourceBundle:@"kb-magnifier-ranged-lo"];
			self.loupeFrameMaskImage = [self _imageNamedFromResourceBundle:@"kb-magnifier-ranged-mask"];
			self.loupeFrameImage = [self _imageNamedFromResourceBundle:@"kb-magnifier-ranged-hi"];
			
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
	frame.origin.x = (newCenter.x - frame.size.width/2.0f);
	frame.origin.y = (newCenter.y - frame.size.height/2.0f);
	
	// make the frame align with pixels
	CGFloat scale = [UIScreen mainScreen].scale;
	frame.origin.x = round(frame.origin.x * scale)/scale;
	frame.origin.y = round(frame.origin.y * scale)/scale;
	
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
							  options:UIViewAnimationOptionCurveEaseOut
						  animations:^{
							  self.alpha = 1.0;
							  self.transform = CGAffineTransformIdentity;
						  }
						  completion:^(BOOL finished) {
						  }];
}

- (void)dismissLoupeTowardsLocation:(CGPoint)location
{
	[UIView animateWithDuration:DTLoupeAnimationDuration
								 delay:0
							  options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut
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
- (void)refreshLoupeContent
{
	if (_seeThroughMode)
	{
		return;
	}
	
	UIGraphicsBeginImageContextWithOptions(_loupeContentsLayer.bounds.size, YES, 0);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
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

    //Using drawViewHierarchyInRect instead of renderInContext if available to avoid crashes
    if ([_targetRootView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [_targetRootView drawViewHierarchyInRect:_targetRootView.bounds afterScreenUpdates:YES];
    } else {
        [_targetRootView.layer renderInContext:ctx];
    }
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	_loupeContentsLayer.contents = (__bridge id)(image.CGImage);
	
	UIGraphicsEndImageContext();
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
@synthesize layerDelegate =_layerDelegate;

@end
