Change Log
==========

This is the history of version updates.

Version 1.5.9

- FIXED: Orientation problem on iOS 9 and newer

Version 1.5.8

- FIXED: Invalid Geometry Crash fix
- FIXED: Orientation problems under iOS 9

Version 1.5.7

- ADDED: DTLoupe resource bundle can now also be in framework resources

Version 1.5.6

- FIXED: Invalid layer geometry might cause crash
- FIXED: iOS 8 deprecation warning about using interfaceOrientation 

Version 1.5.5

- FIXED: Rotation problem on iOS 8 

Version 1.5.4

- FIXED: iOS 6 compatibility issue workaround by moving loupe content delegate into separate class
- FIXED: Warning about incorrect animation option
- CHANGED: Improved loupe content update by using layer display method as opposed to drawing the layer
- CHANGED: Reverted fix for status bar content mode from 1.5.2

Version 1.5.3

- FIXED: Potential crash when presenting the editor in a modal view controller
- CHANGED: Improved loupe smoothness when panning
- CHANGED: Modernized method of getting loupe contents
- ADDED: Support for arm64

Version 1.5.2

- FIXED: On iOS 7 a light status bar content mode would revert to black
- CHANGED: Updated podspec for building the resource bundle via new Cocoapods option
