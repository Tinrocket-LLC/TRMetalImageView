//
//  TRCenteringClipView.m
//  TinrocketCommonMacLibrary
//
//  Created by John Balestrieri on 7/10/18.
//  Copyright © 2018 Tinrocket, LLC. All rights reserved.
//

#import "TRCenteringClipView.h"



@implementation TRCenteringClipView

#pragma mark - Overridden

- (NSRect)constrainBoundsRect:(NSRect)proposedBounds {
	NSRect constrainedClipViewBounds = [super constrainBoundsRect:proposedBounds];
	
	if (!self.documentView) return constrainedClipViewBounds;
	CGRect documentViewRect = self.documentView.frame;

	CGFloat magScale = self.enclosingScrollView.magnification;
	
	if (documentViewRect.size.width < constrainedClipViewBounds.size.width) {
		constrainedClipViewBounds.origin.x = (proposedBounds.size.width * magScale - constrainedClipViewBounds.size.width) * 0.5;
	}
	
	if (documentViewRect.size.height < constrainedClipViewBounds.size.height) {
		constrainedClipViewBounds.origin.y = (proposedBounds.size.height * magScale - constrainedClipViewBounds.size.height) * 0.5;
	}

	return constrainedClipViewBounds;
}

@end
