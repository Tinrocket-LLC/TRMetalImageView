//
//  TRMTKView.m
//  TR-Photo-App-Template
//
//  Created by John Balestrieri on 11/5/18.
//  Copyright © 2018 Tinrocket, LLC. All rights reserved.
//

#import "TRMTKImageView.h"
#import <CoreImage/CoreImage.h>



@interface TRMTKImageView ()
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) CIContext *ciContext;
@end


@implementation TRMTKImageView

#pragma mark - Lifecycle

- (void)awakeFromNib {
	[super awakeFromNib];

	// Metal
	self.device = MTLCreateSystemDefaultDevice();
	self.commandQueue = [self.device newCommandQueue];
	
	// Core Image
	NSDictionary *options = @{kCIContextWorkingColorSpace : [NSNull null],
							  kCIContextCacheIntermediates : @(NO) // Best for video, based on WWDC 20 video recs ("Optimize the Core Image pipeline for your video app"). Will help with rendering complex CIImages
	};
	self.ciContext = [CIContext contextWithMTLDevice:self.device options:options];
	
	
	self.delegate = self;
	self.framebufferOnly = NO;	// To allow CI to render to it using Metal Compute
	self.presentsWithTransaction = YES; // Best results when things get laggy;
	self.preferredFramesPerSecond = 60;
	self.paused = YES;
    self.enableSetNeedsDisplay = YES;
	self.autoResizeDrawable = NO;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
	self.layerContentsPlacement = NSViewLayerContentsPlacementCenter;
	self.layer.opaque = NO; // To support clearing with a transparent color
	self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
	
	self.layer.contentsScale = self.window.backingScaleFactor;
}


#pragma mark - Overridden


- (void)viewDidChangeBackingProperties {
	[super viewDidChangeBackingProperties];
	
	self.layer.contentsScale = self.window.backingScaleFactor;
	
	[self setNeedsDisplay:YES];
}


- (void)layout {
	[super layout];
	
	[self recomputeDrawableSize];
}


#pragma mark - Private

- (CGRect)viewPort {
	if (self.scrollView) {
		NSRect r = self.scrollView.frame;
//		NSRect r = self.scrollView.layer.presentationLayer.frame;
		
		r = [self.scrollView convertRect:r toView:self.scrollView.documentView];
		
		return r;
	}
	
	return self.frame;
}


- (void)recomputeDrawableSize {
	CAMetalLayer *layer = (CAMetalLayer *)self.layer;
	CGSize framePixelSize = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(self.layer.contentsScale, self.layer.contentsScale));
	CGFloat s = self.layer.contentsScale;
	if (!CGSizeEqualToSize(framePixelSize, layer.drawableSize) && !CGSizeEqualToSize(framePixelSize, CGSizeZero)) {
		layer.drawableSize = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(s, s));
//		[self setNeedsDisplay:YES];
	}
}


#pragma mark - Public
#pragma mark Getters & Setters

- (void)setImage:(CIImage *)image {
	_image = image;
	
	[self setNeedsDisplay:YES];
}


#pragma mark - Delegates
#pragma mark MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
	CGFloat screenScale = self.layer.contentsScale;
	
	[self recomputeDrawableSize];

	static CGColorSpaceRef cs;
	if (cs == NULL) cs = CGColorSpaceCreateDeviceRGB();

	// Create a new command buffer for each renderpass to the current drawable
	id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
	commandBuffer.label = @"MetalCommandBuffer";
	
	if (self.image &&
		view.currentDrawable &&
		self.currentRenderPassDescriptor) {

		// Clear with self.clearColor
		self.currentRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
		id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
		[encoder endEncoding];
		
		CIImage *renderImage = self.image;

		CGFloat magnification = 1.0;
		if (self.scrollView)
			magnification = self.scrollView.magnification;
		CGFloat finalScale = magnification * screenScale;
		
		if (finalScale >= 1) {
			renderImage = [renderImage imageBySamplingNearest]; // Pixelate
		} else {
			renderImage = [renderImage imageBySamplingLinear]; // AA
		}
		
		CGAffineTransform t = CGAffineTransformIdentity;
		t = CGAffineTransformScale(t, finalScale, finalScale);
		renderImage = [renderImage imageByApplyingTransform:t]; // Optional: Use highQualityDownsample:YES version of method, maybe, if not on retina screen, etc.
		
		CGRect vp = [self viewPort];
		vp = CGRectApplyAffineTransform(vp, CGAffineTransformMakeScale(magnification * screenScale, magnification * screenScale));
		vp = CGRectInset(vp, -self.borderWidth * screenScale, -self.borderWidth * screenScale);

		[_ciContext render:renderImage
			  toMTLTexture:view.currentDrawable.texture
			 commandBuffer:commandBuffer
					bounds:vp
				colorSpace:cs];
		
		if (!self.presentsWithTransaction)
			[commandBuffer presentDrawable:view.currentDrawable];
	}
	
	// Finalize rendering here & push the command buffer to the GPU
	[commandBuffer commit];
	
	if (self.presentsWithTransaction) {
		[commandBuffer waitUntilScheduled];
		[view.currentDrawable present];
	}
}


- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
	// Not used because we manually set drawable size; stub added to silence warning
}

@end
