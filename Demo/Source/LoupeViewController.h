//
//  LoupeViewController.h
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2013 Drobnik KG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTLoupeView.h"
#import "SnappySlider.h"

@class DTLoupeView;

@interface LoupeViewController : UIViewController {

    DTLoupeStyle    _loopStyle;
    float           _loupeMagnification;
    float           _loupeImageOffSet;
    
    SnappySlider    *_magnificationSlider;
    UILabel         *_magnificationLabel;
    
    UIButton        *_topThumb;
    UIButton        *_bottomThumb;
    
}

- (IBAction)changeLoupeStyle:(id)sender;
- (IBAction)changeMagnification:(id)sender;

@property (nonatomic, retain) IBOutlet SnappySlider *magnificationSlider;
@property (nonatomic, retain) IBOutlet UILabel *magnificationLabel;
@property (nonatomic, retain) IBOutlet UIButton *topThumb;
@property (nonatomic, retain) IBOutlet UIButton *bottomThumb;

@end
