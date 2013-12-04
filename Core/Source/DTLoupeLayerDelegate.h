//
//  DTLoupeLayerDelegate.h
//  Pods
//
//  Created by Joshua Grenon on 11/11/13.
//
//

@class DTLoupeView;

/**
 Extra delegate for the DTLoupe's content layer. Forwards the display action to the loupe view. Disables all animation actions.
 */

@interface DTLoupeLayerDelegate : NSObject

/**
 Designated Initializer
 @property loupeView The DTLoupeView to forward the -displayLayer: method to.
 */
- (instancetype)initWithLoupeView:(DTLoupeView *)loupeView;

@end
