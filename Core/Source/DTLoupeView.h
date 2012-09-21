//
//  DTLoupeView.h
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

typedef enum
{
    DTLoupeStyleCircle = 0,
    DTLoupeStyleRectangle,
    DTLoupeStyleRectangleWithArrow,
} DTLoupeStyle;


// add the safety of weak if available
#ifdef __WEAK
#undef __WEAK
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 50000
#define __WEAK __weak
#define WEAK weak
#else
#define __WEAK __unsafe_unretained
#define WEAK assign
#endif


extern NSString * const DTLoupeDidHide;

@interface DTLoupeView : UIView

@property(nonatomic,assign) CGPoint touchPoint;
@property(nonatomic, assign) CGPoint touchPointOffset;

@property(nonatomic,assign) DTLoupeStyle style;
@property(nonatomic,assign) CGFloat magnification;
@property(nonatomic,assign) CGPoint magnifiedImageOffset;

@property(nonatomic,WEAK) UIView *targetView;

@property(nonatomic,assign) BOOL drawDebugCrossHairs;
@property(nonatomic,assign) BOOL seeThroughMode;

+ (DTLoupeView *)sharedLoupe;

- (void)presentLoupeFromLocation:(CGPoint)location;
- (void)dismissLoupeTowardsLocation:(CGPoint)location;

- (BOOL)isShowing;

@end
