//
//  LoupeViewController.h
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTLoupeView.h"
#import "SnappySlider.h"

@class DTLoupeView;

@interface LoupeViewController : UIViewController {

    DTLoupeView     *_loupe;
    
    DTLoupeStyle    _loopStyle;
    float           _loupeMagnification;
    
    SnappySlider *_magnificationSlider;
    UILabel *_magnificationLabel;
}

- (IBAction)changeLoupeStyle:(id)sender;
- (IBAction)changeMagnification:(id)sender;

@property (nonatomic, retain) IBOutlet SnappySlider *magnificationSlider;
@property (nonatomic, retain) IBOutlet UILabel *magnificationLabel;

- (void)removeLoupe;

@end
