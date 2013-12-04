//
//  LoupeViewController.m
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2013 Drobnik KG. All rights reserved.
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
    
    _loopStyle = DTLoupeStyleCircle; // Default to match Segment Controller & Apple's Default
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

}


- (void)dealloc
{
    [_magnificationSlider release];
    [_magnificationLabel release];
    [_topThumb release];
    [_bottomThumb release];
    [super dealloc];
}

#pragma mark - Actions

- (IBAction)changeLoupeStyle:(id)sender {
    
    NSInteger segmentIndex = [sender selectedSegmentIndex];
    
    switch (segmentIndex) {
        case 0 :
        default:
            _loopStyle = DTLoupeStyleCircle;
            break;
        case 1 :
            _loopStyle = DTLoupeStyleRectangle;
            break;
        case 2 :
            _loopStyle = DTLoupeStyleRectangleWithArrow;
            break;
    }
  
}

- (IBAction)changeMagnification:(id)sender 
{
    // We will allow magnification from 1 (Actual Size) to 3 x
    // This means that the centre of the slider represents 1.25
    // which is the default magnification
        
    _loupeMagnification = (float)[(UISlider*)sender value]/100;
    _magnificationLabel.text = [NSString stringWithFormat:@"Magnification: %.2f (Default = %.2f)", _loupeMagnification, DTDefaultLoupeMagnification];
}

#pragma mark - Loupe Methods

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture 
{
	DTLoupeView *loupe = [DTLoupeView sharedLoupe];
    CGPoint touchPoint = [gesture locationInView:self.view];
	
	switch (gesture.state) 
	{
		case UIGestureRecognizerStateBegan:
		{
			// Init loupe just once for performance
			// It should be removed/release etc somewhere else when 
			// editing is complete or maybe in dealloc

			loupe.style = _loopStyle;
			loupe.targetView = self.view;
			
			// The Initial TouchPoint needs to be set before we set the style
			loupe.touchPoint = touchPoint;
			
			// Normally you would set the loupe that require
			//  i.e. _loupe.type = DTLoupeStyleRectangle;
			// In this project we using our UIControls Values
			
			// Default Magnification is 1.2
			loupe.magnification = _loupeMagnification;
			
			[loupe presentLoupeFromLocation:touchPoint];
			
			
			break;
		}
			
		case UIGestureRecognizerStateChanged:
		{
			// Show Cursor and position between glyphs
			loupe.touchPoint = touchPoint;
			
			break;
		}
			
		default:
		{
			[loupe dismissLoupeTowardsLocation:touchPoint];
			
			break;
		}
	}
}

- (void)exampleTopThumbPress:(UILongPressGestureRecognizer *)gesture
{
	DTLoupeView *loupe = [DTLoupeView sharedLoupe];
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    UIGestureRecognizerState state = gesture.state;
    
    if (state == UIGestureRecognizerStateBegan)
	{
		loupe.style = DTLoupeStyleRectangleWithArrow;
		loupe.targetView = self.view;
        
        // The Initial TouchPoint needs to be set before we set the style
        loupe.touchPoint = touchPoint;
        
        loupe.magnification = _loupeMagnification;
        
        loupe.magnifiedImageOffset = CGPointMake(0, -28.00f); // Approx offset
		
		[loupe presentLoupeFromLocation:touchPoint];
    }
    
    if (state == UIGestureRecognizerStateChanged) {
        // Not for this example        
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
	{
 		[loupe dismissLoupeTowardsLocation:CGPointZero];
        return;
    }
    
}

- (void)exampleBottomThumbPress:(UILongPressGestureRecognizer *)gesture
{
 	DTLoupeView *loupe = [DTLoupeView sharedLoupe];
	CGPoint touchPoint = [gesture locationInView:self.view];
    
    UIGestureRecognizerState state = gesture.state;
    
    if (state == UIGestureRecognizerStateBegan)
	{
		loupe.style = DTLoupeStyleRectangleWithArrow;
		loupe.targetView = self.view;
        
        // The Initial TouchPoint needs to be set before we set the style
        loupe.touchPoint = touchPoint;
        
        loupe.magnification = _loupeMagnification;
        
		loupe.magnifiedImageOffset = CGPointMake(0, 12.00f); // Approx offset
    }
    
    if (state == UIGestureRecognizerStateChanged) {
        // Not for this example        
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
		[loupe dismissLoupeTowardsLocation:CGPointZero];
        return;
    }
    
}

@end
