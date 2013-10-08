//
//  DTLoupeView.h
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

/**
 The style the a loupe can show
 */
typedef NS_ENUM(NSUInteger, DTLoupeStyle)
{
	/**
	 Loupe is a circle
	 */
    DTLoupeStyleCircle = 0,
	
	/**
	 Loupe is a ranged rectangle without arrow
	 */
    DTLoupeStyleRectangle,
	
	/**
	 Loupe is a ranged rectangle with arrow
	 */
    DTLoupeStyleRectangleWithArrow,
};

extern NSString * const DTLoupeDidHide;

// add the safety of weak if available

// if deployment target >= iOS 5 we can use weak
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 50000
#define __WEAK __weak
#define WEAK weak
#else
#define __WEAK __unsafe_unretained
#define WEAK assign
#endif

/**
 DTLoupeView represents the "magnifying glass" shown when positioning a caret or ranged selection. It has three different styles: the regular round loupe, a ranged selection loupe with an arrow at the bottom and a rectangual loupe without arrow.
 
 You should not create instances of DTLoupeView, but retrieve a reference to the shared loupe instance via sharedLoupe.
 */
@interface DTLoupeView : UIView

/**
 @name Getting the Shared Loupe
 */

/**
 Get the shared instance of the loupe
 @returns A reference to the loupe
 */
+ (DTLoupeView *)sharedLoupe;

/**
 @name Presenting the Loupe
 */

/**
 Presents the loupe with an animation beginning from the given location
 @param location The point to begin the presenting aninimation from
 */
- (void)presentLoupeFromLocation:(CGPoint)location;

/**
 Dismisses the loupe with an animation towards a location
 @param location The point to animate the dismissal towards
 */
- (void)dismissLoupeTowardsLocation:(CGPoint)location;

/**
 Moves the loupe to be showing the location at the current touch point
 */
@property(nonatomic, assign) CGPoint touchPoint;


/**
 @name Changing the Loupe Style
 */

/**
 See-Through Mode is used by Apple if the touch point leaves the visible area of editing views. This makes the loupe slightly translucent and does not display a magnified image.
 */
@property(nonatomic,assign) BOOL seeThroughMode;

/**
 The loupe style. 
 
 Available loupe styles are:
 
 - DTLoupeStyleCircle
 - DTLoupeStyleRectangle
 - DTLoupeStyleRectangleWithArrow
 */
@property(nonatomic,assign) DTLoupeStyle style;

/**
 The magnification factor of the loupe, defaults to 1.2
 */
@property(nonatomic,assign) CGFloat magnification;

/**
 A static offset to apply to the touch point. Setting the loupe style resets this to default CGSizeZero.
 */
@property(nonatomic, assign) CGSize touchPointOffset;

/**
 Different loupes have a different vertical offset for the magnified image (otherwise the touchpoint = equals the centre of maginified image). Setting the loupe style also sets the appropriate offset. This property can be used to customize the offset
 */
@property(nonatomic, assign) CGPoint magnifiedImageOffset;


/**
 @name Getting Information
 */

/**
 The target view. This determines the coordinate system in which touchPoint is referring to.
 */
@property(nonatomic, WEAK) UIView *targetView;

/**
 Determine if the the loupe is currently showing
 @returns `YES` if the receiver is visible
 */
- (BOOL)isShowing;

@end
