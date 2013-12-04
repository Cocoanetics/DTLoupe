//
//  DTLoupeAppDelegate.h
//  DTLoupe
//
//  Created by Michael Kaye on 22/06/2011.
//  Copyright 2013 Drobnik KG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoupeDemoAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
