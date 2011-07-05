//
//  DTLoupeView.h
//  DTLoupe
//
//  Created by Michael Kaye on 21/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>

/* trying out git svn */

typedef enum {
    DTLoupeOverlayNone,
    DTLoupeOverlayCircle,
    DTLoupeOverlayRectangle,
    DTLoupeOverlayRectangleWithArrow,
} DTLoupeStyle;

@interface DTLoupeView : UIView {
    
    DTLoupeStyle    _style;                     // Type of Loupe; None, Circle, Rectangle, Rectangle With Arrow

    CGPoint         _touchPoint;                // The point at which to display (in our target view's bounds coordinates)
    CGFloat         _magnification;             // How much to magnify the view
    CGFloat         _loupeImageOffset;          // Offset of vertical position of magnified image from centre of Loupe NB Touchpoint is normally centered in Loupe

    UIView          *_targetView;               // View to Magnify
    
    UIImage         *loupeFrameImage;           // A Loupe/Magnifier is based on 3 images. Background, Mask & Main
    UIImage         *loupeFrameBackgroundImage;
    UIImage         *loupeFrameMaskImage;
    
    CGRect          loupeFramePosition;         // The frame of the Loupe Image, expressed with (0,0) at the (unmagnified) touch point

    BOOL            _drawDebugCrossHairs;       // Draws cross hairs for debugging
}

@property(readwrite,nonatomic,assign) CGPoint touchPoint;

@property(readwrite,nonatomic,assign) DTLoupeStyle style;
@property(readwrite,nonatomic,assign) CGFloat magnification;
@property(readwrite,nonatomic,assign) CGFloat loupeImageOffset;

@property(readwrite,nonatomic,assign) UIView *targetView;

@property(readwrite,nonatomic,assign) BOOL drawDebugCrossHairs;

@end
