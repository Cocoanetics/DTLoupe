//
//  DTLoupeLayerDelegate.h
//  DTLoupe
//
//  Created by Joshua Grenon on 11/11/13.
//  Copyright 2013 Drobnik KG. All rights reserved.
//

@class DTLoupeView;

/**
 Extra delegate for the DTLoupe's content layer. Forwards the display action to the loupe view. Disables all animation actions.
 */

@interface DTLoupeLayerDelegate : NSObject

/**
 Designated Initializer
 @param loupeView The DTLoupeView to forward the -displayLayer: method to.
 */
- (instancetype)initWithLoupeView:(DTLoupeView *)loupeView;

@end
