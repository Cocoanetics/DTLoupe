//
//  DTLoupeAppDelegate.h
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2011 sendmetospace.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
