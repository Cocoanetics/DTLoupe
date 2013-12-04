//
//  MagnifierViewController.m
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2013 Drobnik KG. All rights reserved.
//

#import "AppleLoupeController.h"


@implementation AppleLoupeController
@synthesize exampleTextView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [exampleTextView becomeFirstResponder];
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
    [self setExampleTextView:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc
{
    [exampleTextView release];
    [super dealloc];
}

- (IBAction)hideKeyboard:(id)sender {
    
//    [exampleTextView resignFirstResponder];
    
    self.tabBarController.selectedIndex = 0;
}


@end
