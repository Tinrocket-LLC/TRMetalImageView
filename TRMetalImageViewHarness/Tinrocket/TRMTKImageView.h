//
//  TRMTKView.h
//  TR-Photo-App-Template
//
//  Created by John Balestrieri on 11/5/18.
//  Copyright © 2018 Tinrocket, LLC. All rights reserved.
//

#import <MetalKit/MetalKit.h>



NS_ASSUME_NONNULL_BEGIN

@interface TRMTKImageView : MTKView <MTKViewDelegate>
@property (strong, nonatomic) CIImage *image;
@property (strong, nonatomic) IBOutlet NSScrollView *scrollView;
@property (assign, nonatomic) CGFloat borderWidth; // You can use an oversized control to work around missing image area when the view is resized
@end

NS_ASSUME_NONNULL_END
