//
//  MagnifierViewController.h
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AppleLoupeController : UIViewController {
    
    UITextView *exampleTextView;
}
- (IBAction)hideKeyboard:(id)sender;

@property (nonatomic, retain) IBOutlet UITextView *exampleTextView;

@end
