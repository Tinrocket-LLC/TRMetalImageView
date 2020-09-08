//
//  TRScrollView.m
//  TinrocketCommonMacLibrary
//
//  Created by John Balestrieri on 8/1/18.
//  Copyright © 2018 Tinrocket, LLC. All rights reserved.
//

#import "TRScrollView.h"
#import "TRCenteringClipView.h"




@interface TRScrollView ()
@property (strong, nonatomic) NSArray *zoomStops;
@property (assign, nonatomic) NSLayoutConstraint *documentWidthConstraintOverride;
@property (assign, nonatomic) NSLayoutConstraint *documentHeightConstraintOverride;
@end


@implementation TRScrollView {
	CGPoint _mouseDragStart;
	CGPoint _mouseDragLast;
	CGPoint _documentOriginDragStart;
    BOOL _isMouseDown;
}

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	if (self) {
		[self sharedInit];
	}
	
	return self;
}


- (instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	if (self) {
		[self sharedInit];
	}
	
	return self;
}


- (void)sharedInit {	
	self.minMagnification = 0.025;
	self.maxMagnification = 32.0;
		
	// These are the standard zoom stops that Preview.app supports
	self.zoomStops = @[
					   @(0.025),
					   @(0.05),
					   @(0.1),
					   @(0.15),
					   @(0.2),
					   @(0.25), // Not supported in Preview.app
					   @(0.3),
					   @(0.4),
					   @(0.5),
					   @(0.75),
					   @(1.0),
					   @(1.5),
					   @(2.0),
					   @(3.0),
					   @(4.0),
//					   @(5.0), // Not supported in Preview.app
//					   @(6.0),
					   @(8.0),
					   @(16.0),
					   @(24.0),
					   @(32.0),
//					   @(48.0),
					   @(64.0),
					   @(128.0),
					   ];
	
	// Still appears white when system setting is "Show scroll bars: Automatically based on mouse or trackpad"
	self.scrollerStyle = NSScrollerStyleOverlay; // Otherwise, scroll bar backgrounds will appear white
}


- (void)awakeFromNib {
	[super awakeFromNib];

	// Required for scrolling updates
	[self.contentView setPostsFrameChangedNotifications:YES];
	[self.contentView setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(viewDidChangeSizeOrPosition:)
												 name:NSViewFrameDidChangeNotification
											   object:self.contentView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(viewDidChangeSizeOrPosition:)
												 name:NSViewBoundsDidChangeNotification
											   object:self.contentView];
	
}


#pragma mark - Overridden

- (void)layout {
	[super layout];
	
	if (_lockToAspectFit)
		[self zoomAspectFitAnimated:NO];
}


- (void)mouseDown:(NSEvent *)event {
    if (event.window.titlebarAppearsTransparent) {
        if (event.locationInWindow.y > CGRectGetHeight(event.window.contentLayoutRect)) {
            return;
        }
    }

	_mouseDragStart = event.locationInWindow;
	_documentOriginDragStart = self.documentVisibleRect.origin;
    _isMouseDown = YES;
}


- (void)mouseDragged:(NSEvent *)event {
    if (!_isMouseDown) return;

	_mouseDragLast = event.locationInWindow;
	CGVector delta = CGVectorMake(_mouseDragStart.x - _mouseDragLast.x, _mouseDragStart.y - _mouseDragLast.y);
	CGFloat inverseScale = 1.0 / self.magnification;
	
	[self.documentView scrollPoint:CGPointMake(_documentOriginDragStart.x + delta.dx * inverseScale, _documentOriginDragStart.y + delta.dy * inverseScale)];
	
    if ([self.macScrollViewDelegate TRMacScrollViewCanDragContentsToScroll:self]) {
        [[NSCursor closedHandCursor] set];
    }
}


- (void)mouseUp:(NSEvent *)event {
    if (!_isMouseDown) return;
    
    _isMouseDown = NO;
	[[NSCursor arrowCursor] set];
}


// Note: Implementing - (void)scrollWheel:(NSEvent *)event; even if we just call the super, seems to stop trackpad scrolls.
// The default implementation handles mouse scroll and trackpad scrolling without issue.
// (see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingTouchEvents/HandlingTouchEvents.html)
//- (void)scrollWheel:(NSEvent *)event {
//	[super scrollWheel:event];
//}


- (void)magnifyWithEvent:(NSEvent *)event {
    [super magnifyWithEvent:event];
    
    [self.macScrollViewDelegate TRMacScrollViewDidUpdateZoom:self];
}


- (void)cursorUpdate:(NSEvent *)event {
    if (_isMouseDown) {
        // Swallow the event to keep the closed hand cursor while the user drags.
        return;
    }

    [super cursorUpdate:event];
}


- (CGFloat)maxMagnification {
	CGFloat m = [super maxMagnification];
	
	return m;
}


- (void)setMagnification:(CGFloat)magnification {
	[super setMagnification:magnification];
	
	[self.macScrollViewDelegate TRMacScrollViewDidUpdateZoom:self];
}


#pragma mark - Public

- (void)setDocumentSize:(NSSize)theDocumentSize {
	[self.documentView removeConstraint:self.documentWidthConstraintOverride];
	[self.documentView removeConstraint:self.documentHeightConstraintOverride];

	self.documentWidthConstraintOverride = nil;
	self.documentHeightConstraintOverride = nil;

	if (CGSizeEqualToSize(theDocumentSize, CGSizeZero)) {
		[self layout];
		return;
	}

	self.documentWidthConstraintOverride = [NSLayoutConstraint constraintWithItem:self.documentView
																		attribute:NSLayoutAttributeWidth
																		relatedBy:NSLayoutRelationEqual
																		   toItem:nil
																		attribute:NSLayoutAttributeNotAnAttribute
																	   multiplier:1.0f
																		 constant:theDocumentSize.width];

	self.documentHeightConstraintOverride = [NSLayoutConstraint constraintWithItem:self.documentView
																		 attribute:NSLayoutAttributeHeight
																		 relatedBy:NSLayoutRelationEqual
																			toItem:nil
																		 attribute:NSLayoutAttributeNotAnAttribute
																		multiplier:1.0f
																		  constant:theDocumentSize.height];

	[self.documentView addConstraint:self.documentWidthConstraintOverride];
	[self.documentView addConstraint:self.documentHeightConstraintOverride];
	[self.documentView updateConstraints];
	
	[self layout];
}


- (BOOL)canZoomIn {
    return (self.magnification < self.maxMagnification);
}


- (BOOL)canZoomOut {
	return (self.magnification > [self.zoomStops.firstObject floatValue]);
}


- (BOOL)canZoomActualSize {
    return (self.magnification != 1.0);
}


- (void)zoomReset:(BOOL)animated {
	if (self.lockToAspectFit) {
		[self zoomAspectFitAnimated:animated];
	} else {
		[self zoomTo:1.0 animated:animated];
	}
}


- (void)zoomTo:(CGFloat)theScale animated:(BOOL)animated {
	self.lockToAspectFit = NO;

	theScale = MIN(MAX(0.0, theScale), self.maxMagnification);
	
	if (animated) {
		if ([self.macScrollViewDelegate respondsToSelector:@selector(TRMacScrollViewWillBeginAnimation:)])
			[self.macScrollViewDelegate TRMacScrollViewWillBeginAnimation:self];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			context.duration = 0.15;
			self.animator.magnification = theScale;
		} completionHandler:^{
			[self.documentView setNeedsLayout:YES];

			if ([self.macScrollViewDelegate respondsToSelector:@selector(TRMacScrollViewDidEndAnimation:)])
				[self.macScrollViewDelegate TRMacScrollViewDidEndAnimation:self];
		}];
	} else {
		self.magnification = theScale;
		[self.macScrollViewDelegate TRMacScrollViewDidUpdateZoom:self];
	}
}


- (void)zoomIn:(BOOL)animated {
	self.lockToAspectFit = NO;

	if (![self canZoomIn]) return;
	
	CGFloat currentMag = self.magnification;
	
	for (NSNumber *n in self.zoomStops) {
		CGFloat currentValue = [n floatValue];
		if (currentValue > currentMag) {
			[self zoomTo:currentValue animated:animated];
			
			return;
		}
	}
}


- (void)zoomOut:(BOOL)animated {
	self.lockToAspectFit = NO;

	if (![self canZoomOut]) return;

	CGFloat currentMag = self.magnification;
	
	NSEnumerator *e = [self.zoomStops reverseObjectEnumerator];
	for (NSNumber *n in e) {
		CGFloat currentValue = [n floatValue];
		if (currentValue < currentMag) {
			[self zoomTo:currentValue animated:animated];

			return;
		}
	}
}


- (void)zoomAspectFitAnimated:(BOOL)animated {
	CGSize frameSize = self.frame.size;
	CGSize documentSize = self.documentView.frame.size;
	
	CGFloat scale = MIN(frameSize.width / (documentSize.width), frameSize.height / (documentSize.height));
	
	if (isinf(scale)) scale = 1.0;
	if (_lockToAspectFitDoNotMagnify && scale > 1.0) scale = 1.0;
	
	BOOL currentLockValue = self.lockToAspectFit;
	[self zoomTo:scale animated:animated];
	self.lockToAspectFit = currentLockValue;
}


- (void)zoomAspectFillAnimated:(BOOL)animated {
	CGSize frameSize = self.frame.size;
	CGSize documentSize = self.documentView.frame.size;
	
    CGFloat scale = MAX(frameSize.width / (documentSize.width), frameSize.height / (documentSize.height));

    if (isinf(scale)) scale = 1.0;
    if (_lockToAspectFitDoNotMagnify && scale > 1.0) scale = 1.0;

    BOOL currentLockValue = self.lockToAspectFit;
    [self zoomTo:scale animated:animated];
    self.lockToAspectFit = currentLockValue;
}


- (void)toggleZoomInOutAnimated:(BOOL)animated {
    // Presumably the user wanted to zoom, so turn off DoNotMagnify.
    self.lockToAspectFitDoNotMagnify = NO;

    CGSize frameSize = self.frame.size;
    CGSize documentSize = self.documentView.frame.size;

    CGFloat widthRatio = frameSize.width / (documentSize.width);
    CGFloat heightRatio = frameSize.height / (documentSize.height);

    CGFloat aspectFillScale = MAX(widthRatio, heightRatio);
    CGFloat aspectFitScale = MIN(widthRatio, heightRatio);

    if (isinf(aspectFillScale)) aspectFillScale = 1.0;
    if (isinf(aspectFitScale)) aspectFitScale = 1.0;

    NSArray *unorderedZoomSteps = @[@(aspectFillScale), @(aspectFitScale), @(1)];
    NSArray *zoomSteps = [unorderedZoomSteps sortedArrayUsingSelector:@selector(compare:)];

    NSNumber *nextZoom = zoomSteps[0];
    for (NSNumber *zoomStep in zoomSteps) {
        if (self.magnification < zoomStep.doubleValue) {
            nextZoom = zoomStep;
            break;
        }
    }
    [self zoomTo:nextZoom.doubleValue animated:animated];
}


#pragma mark - Delegates
#pragma mark NSNotificationCenter

- (void)viewDidChangeSizeOrPosition:(id)sender {
	[self.macScrollViewDelegate TRMacScrollViewDidUpdateZoom:self];
}

@end
