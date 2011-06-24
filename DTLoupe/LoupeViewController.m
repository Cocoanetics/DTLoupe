//
//  LoupeViewController.m
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import "LoupeViewController.h"
#import "DTLoupeView.h"

@implementation LoupeViewController
@synthesize magnificationSlider = _magnificationSlider;
@synthesize magnificationLabel = _magnificationLabel;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    UILongPressGestureRecognizer *longTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showLoupe:)];
    [self.view addGestureRecognizer:longTouch];
    [longTouch release];
    
    _loopStyle = DTLoupeOverlayCircle; // Default to match Segment Controller & Apple's Default
    
    _loupeMagnification = 1.25; // Default to match Slider & Apple's Default
	NSArray *detents = [NSArray arrayWithObjects:[NSNumber numberWithInt:100], [NSNumber numberWithInt:125],
						[NSNumber numberWithInt:150], [NSNumber numberWithInt:200],
						[NSNumber numberWithInt:250], nil];
	
	_magnificationSlider.detents = detents;
    _magnificationSlider.value = 125;
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
    [super dealloc];
}

#pragma mark - Actions

- (IBAction)changeLoupeStyle:(id)sender {
    
    int segmentIndex = [sender selectedSegmentIndex];
    
    switch (segmentIndex) {
        case 0 :
        default:
            _loopStyle = DTLoupeOverlayCircle;
            break;
        case 1 :
            _loopStyle = DTLoupeOverlayRectangle;
            break;
        case 2 :
            _loopStyle = DTLoupeOverlayRectangleWithArrow;
            break;
    }
  
}

- (IBAction)changeMagnification:(id)sender {
    // We will allow magnification from 1 (Actual Size) to 3 x
    // This means that the centre of the slider represents 1.25
    // which is the default magnification
        
    _loupeMagnification = (float)[(UISlider*)sender value]/100;
    _magnificationLabel.text = [NSString stringWithFormat:@"Magnification: %.2f (Default = 1.25)", _loupeMagnification];

}

#pragma mark - Loupe Methods

- (void)showLoupe:(UILongPressGestureRecognizer *)gesture {
    
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    //    NSLog(@"inspect with state %d at %@ with required taps %d, number of touches %d", gesture.state, pp, [gesture numberOfTapsRequired], [gesture numberOfTouches]);
    
    UIGestureRecognizerState state = gesture.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        // Init loupe just once for performance
        // It should be removed/release etc somewhere else when 
        // editing is complete or maybe in dealloc
        
        if (!_loupe) {
            _loupe = [[DTLoupeView alloc] initWithFrame:[self.view frame]];
            _loupe.targetView = self.view;
            [self.view.window addSubview:_loupe];
        }
    }
    
    _loupe.touchPoint = touchPoint;
    
    if (state == UIGestureRecognizerStateChanged) {
        // Show Cursor and position between glyphs
        
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        _loupe.style = DTLoupeOverlayNone; // Hide our Loupe
        return;
    }
    
    // Normally you would set the loupe that require
    //    _loupe.type = DTLoupeOverlayRectangle;
    
    // In this project we are setting from our Segmented Control
    _loupe.style = _loopStyle;
    _loupe.magnification = _loupeMagnification;
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
