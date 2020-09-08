//
//  ViewController.m
//  TRMetalImageViewHarness
//
//  Created by John Balestrieri on 8/13/20.
//  Copyright © 2020 Tinrocket, LLC. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import "TRScrollView.h"
#import "TRMTKImageView.h"



// Bear photo by Mark Basarab
// https://unsplash.com/photos/y421kXlUOQk
#define IMAGE_NAME @"mark-basarab-y421kXlUOQk-unsplash.jpg"


@interface ViewController () <TRScrollViewDelegate>
@property (strong, nonatomic) IBOutlet TRScrollView *scrollView;
@property (strong, nonatomic) IBOutlet TRMTKImageView *metalKitImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *metalKitImageViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *metalKitImageViewHeight;
@end


@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.scrollView.macScrollViewDelegate = self;
	
	// Load up an image
	NSURL *url = [[NSBundle mainBundle] URLForImageResource:IMAGE_NAME];
	CIImage *image = [CIImage imageWithContentsOfURL:url];
	
	// Make the image big — well beyond the 16,384 px macOS metal texture limit
	// Note: Larger sizes will increase the amount of work CIAffineTile needs to do if has to draw the whole image. You should use an image pyramid, like map/cartophraphy servers do.
	CGRect largeImageRect = CGRectMake(0, 0, 30000, 30000);
	image = [[CIFilter filterWithName:@"CIAffineTile" keysAndValues:
			   kCIInputImageKey, image,
			   nil].outputImage imageByCroppingToRect:largeImageRect];
	
	// Assign the image to our MTKView-based control
	self.metalKitImageView.image = image;

	// Apply padding around the MTKView-based control to prevent redraw gaps when the view is live-resized
	const CGFloat kBorder = 100;
	self.metalKitImageView.borderWidth = kBorder;
	self.metalKitImageViewWidth.constant = kBorder * 2;
	self.metalKitImageViewHeight.constant = kBorder * 2;

	// Since the MTKView-based control is outside the scroll view hierarchy, we need to tell the scrollview how big the document is
	[self.scrollView setDocumentSize:image.extent.size];

	// For visual debugging
//	self.scrollView.documentView.wantsLayer = YES;
//	self.scrollView.documentView.layer.backgroundColor = [NSColor blueColor].CGColor; // Visualize the actual view managed by the scroll view
//	self.metalKitImageView.layer.backgroundColor = [NSColor redColor].CGColor; // Visualize the MTKView-based control
}


#pragma mark - Private

- (IBAction)zoomIn:(id)sender {
	[self.scrollView zoomIn:YES];
}


- (IBAction)zoomOut:(id)sender {
	[self.scrollView zoomOut:YES];
}


- (IBAction)actualSize:(id)sender {
	[self.scrollView zoomTo:1 animated:YES];
}


- (IBAction)zoomToFit:(id)sender {
	[self.scrollView zoomAspectFitAnimated:YES];
}


- (IBAction)zoomToFill:(id)sender {
	[self.scrollView zoomAspectFillAnimated:YES];
}


#pragma mark - Delegates
#pragma mark TRMacScrollViewDelegate

- (void)TRMacScrollViewDidUpdateZoom:(TRScrollView *)theMacScrollView {
	[self.metalKitImageView setNeedsDisplay:YES];
}


- (BOOL)TRMacScrollViewCanDragContentsToScroll:(TRScrollView *)theMacScrollView {
	return YES;
}

@end
