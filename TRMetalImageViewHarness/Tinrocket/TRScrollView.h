//
//  TRScrollView.h
//  TinrocketCommonMacLibrary
//
//  Created by John Balestrieri on 8/1/18.
//  Copyright © 2018 Tinrocket, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "RFOverlayScrollView.h"
@class TRScrollView;



@protocol TRScrollViewDelegate <NSObject>
- (void)TRMacScrollViewDidUpdateZoom:(TRScrollView *)theMacScrollView;
- (BOOL)TRMacScrollViewCanDragContentsToScroll:(TRScrollView *)theMacScrollView;
@optional
- (void)TRMacScrollViewWillBeginAnimation:(TRScrollView *)theMacScrollView;
- (void)TRMacScrollViewDidEndAnimation:(TRScrollView *)theMacScrollView;
@end


@interface TRScrollView : NSScrollView
@property (weak, nonatomic) id<TRScrollViewDelegate> macScrollViewDelegate;
@property (assign, nonatomic) BOOL lockToAspectFit;
@property (assign, nonatomic) BOOL lockToAspectFitDoNotMagnify; // Prevent images from being zoomed lockToAspectFit is true
- (void)setDocumentSize:(NSSize)theDocumentSize;
- (BOOL)canZoomIn;
- (BOOL)canZoomOut;
- (BOOL)canZoomActualSize;
- (void)zoomReset:(BOOL)animated;
- (void)zoomIn:(BOOL)animated;
- (void)zoomOut:(BOOL)animated;
- (void)zoomTo:(CGFloat)theScale animated:(BOOL)animated;
- (void)zoomAspectFitAnimated:(BOOL)animated;
- (void)zoomAspectFillAnimated:(BOOL)animated;
- (void)toggleZoomInOutAnimated:(BOOL)animated;
@end
