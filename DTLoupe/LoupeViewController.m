//
//  LoupeViewController.m
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import "LoupeViewController.h"
#import "DTLoupeView.h"

#define DTDefaultLoupeMagnification    1.20f       // Match Apple's Magnification

@implementation LoupeViewController
@synthesize magnificationSlider = _magnificationSlider;
@synthesize magnificationLabel = _magnificationLabel;
@synthesize topThumb = _topThumb;
@synthesize bottomThumb = _bottomThumb;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    UILongPressGestureRecognizer *topThumblongTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(exampleTopThumbPress:)];
    [self.topThumb addGestureRecognizer:topThumblongTouch];
    [topThumblongTouch release];

    UILongPressGestureRecognizer *bottomThumblongTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(exampleBottomThumbPress:)];
    [self.bottomThumb addGestureRecognizer:bottomThumblongTouch];
    [bottomThumblongTouch release];

    UILongPressGestureRecognizer *longTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:longTouch];
    [longTouch release];
    
    // UI Defaults
    
    _loopStyle = DTLoupeOverlayCircle; // Default to match Segment Controller & Apple's Default
    _loupeImageOffSet = -4.00f; // default for Circular Loupe
    
    _loupeMagnification = DTDefaultLoupeMagnification; // Default to match Slider & Apple's Default
	NSArray *detents = [NSArray arrayWithObjects:[NSNumber numberWithInt:100], [NSNumber numberWithInt:(DTDefaultLoupeMagnification*100)],
						[NSNumber numberWithInt:150], [NSNumber numberWithInt:200],
						[NSNumber numberWithInt:250], nil];
	
    _magnificationLabel.text = [NSString stringWithFormat:@"Magnification: %.2f (Default = %.2f)", _loupeMagnification, DTDefaultLoupeMagnification];

	_magnificationSlider.detents = detents;
    _magnificationSlider.value = DTDefaultLoupeMagnification*100;
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload
{
    [self setMagnificationSlider:nil];
    [self setMagnificationLabel:nil];
    [self setTopThumb:nil];
    [self setBottomThumb:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self removeLoupe];
}


- (void)dealloc
{
    [self removeLoupe];
    [_magnificationSlider release];
    [_magnificationLabel release];
    [_topThumb release];
    [_bottomThumb release];
    [super dealloc];
}

#pragma mark - Actions

- (IBAction)changeLoupeStyle:(id)sender {
    
    int segmentIndex = [sender selectedSegmentIndex];
    
    switch (segmentIndex) {
        case 0 :
        default:
            _loopStyle = DTLoupeOverlayCircle;
            _loupeImageOffSet = -4.00f;
            break;
        case 1 :
            _loopStyle = DTLoupeOverlayRectangle;
            _loupeImageOffSet = 6.0f; // Just an Example
            break;
        case 2 :
            _loopStyle = DTLoupeOverlayRectangleWithArrow;
            _loupeImageOffSet = -18.00f; // Just an Example
            break;
    }
  
}

- (IBAction)changeMagnification:(id)sender {
    // We will allow magnification from 1 (Actual Size) to 3 x
    // This means that the centre of the slider represents 1.25
    // which is the default magnification
        
    _loupeMagnification = (float)[(UISlider*)sender value]/100;
    _magnificationLabel.text = [NSString stringWithFormat:@"Magnification: %.2f (Default = %.2f)", _loupeMagnification, DTDefaultLoupeMagnification];

}

- (IBAction)crossHairDebug:(id)sender {
    
    UISwitch *crossHairSwitch = (UISwitch*)sender;
    
    _loupe.drawDebugCrossHairs = crossHairSwitch.on;
    
}

#pragma mark - Loupe Methods

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    //    NSLog(@"inspect with state %d at %@ with required taps %d, number of touches %d", gesture.state, pp, [gesture numberOfTapsRequired], [gesture numberOfTouches]);
    
    UIGestureRecognizerState state = gesture.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        // Init loupe just once for performance
        // It should be removed/release etc somewhere else when 
        // editing is complete or maybe in dealloc
        
        if (!_loupe) {
            _loupe = [[DTLoupeView alloc] initWithFrame:CGRectZero];
            _loupe.targetView = self.view;
            
            // NB We are adding to the window so the loupe doesn't get drawn
            // within itself (mirror of a mirror effect)
            // However there should be a better way to do this???
            
            [self.view.window addSubview:_loupe];
        }
        
        // The Initial TouchPoint needs to be set before we set the style
        _loupe.touchPoint = touchPoint;

        // Normally you would set the loupe that require
        //  i.e. _loupe.type = DTLoupeOverlayRectangle;
        // In this project we using our UIControls Values
        
        // Default Magnification is 1.2
        _loupe.magnification = _loupeMagnification;
 
        // Different loupes have a different vertical offset for the magnified image (otherwise the touchpoint = equals the centre of maginified image)
        // Circular Loupe is set -4.0f for example
        // With Rectangular Loupe the offset depends on whether clicking the Top or Bottom Text selection Thumb!
        _loupe.loupeImageOffset = _loupeImageOffSet;
        
        _loupe.style = _loopStyle;

    }
    
    
    if (state == UIGestureRecognizerStateChanged) {
        // Show Cursor and position between glyphs
        _loupe.touchPoint = touchPoint;
        
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
		[loupe 
        //_loupe.style = DTLoupeOverlayNone; // Hide our Loupe
        return;
    }
    
}

- (void)exampleTopThumbPress:(UILongPressGestureRecognizer *)gesture {
    
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    UIGestureRecognizerState state = gesture.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        if (!_loupe) {
            _loupe = [[DTLoupeView alloc] initWithFrame:CGRectZero];
            _loupe.targetView = self.view;
            [self.view.window addSubview:_loupe];
        }
        
        // The Initial TouchPoint needs to be set before we set the style
        _loupe.touchPoint = touchPoint;
        
        _loupe.magnification = _loupeMagnification;
        
        _loupe.loupeImageOffset = -28.00f; // Approx offset
        
        _loupe.style = DTLoupeOverlayRectangleWithArrow;
        
    }
    
    if (state == UIGestureRecognizerStateChanged) {
        // Not for this example        
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        _loupe.style = DTLoupeOverlayNone; // Hide our Loupe
        return;
    }
    
}

- (void)exampleBottomThumbPress:(UILongPressGestureRecognizer *)gesture {
    
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    UIGestureRecognizerState state = gesture.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        if (!_loupe) {
            _loupe = [[DTLoupeView alloc] initWithFrame:CGRectZero];
            _loupe.targetView = self.view;
            [self.view.window addSubview:_loupe];
        }
        
        // The Initial TouchPoint needs to be set before we set the style
        _loupe.touchPoint = touchPoint;
        
        _loupe.magnification = _loupeMagnification;
        
        _loupe.loupeImageOffset = 12.00f; // Approx offset
        
        _loupe.style = DTLoupeOverlayRectangleWithArrow;
        
    }
    
    if (state == UIGestureRecognizerStateChanged) {
        // Not for this example        
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        _loupe.style = DTLoupeOverlayNone; // Hide our Loupe
        return;
    }
    
}

- (void)removeLoupe {
    
    if (_loupe) {
        [_loupe removeFromSuperview];
        [_loupe setTargetView:nil];
        [_loupe release];
        _loupe = nil;
    }
    
}

@end
