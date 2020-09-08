# TRMTKImageView

A macOS Metal-based control that displays images. It's like NSImageView, but faster, and can handle extremely large images.

![](README/Pan_Zoom_8sec.gif)

This repo contains a harness project that shows how to synchronize TRMTKImageView with an NSScrollView, allowing for panning and zooming of large images.


# TRMTKImageView + NSScrollView

While it would be possible to embed the TRMTKImageView (or any MTKView) in an NSScrollView, there are pixel limits to MTKView (16k on macOS) that will limit the maximum size of images you can display.

Rather than embed TRMTKImageView, it is set up outside the NSScrollView hierarchy. TRMTKImageView only draws the visible portion of the NSScrollView's .documentView, speeding up Core Image's on-the-fly rendering.


# Big images

The test harness displays a CIImage that's 30k ✕ 30k; on a retina display, with the harness's 32✕ magnification, that's 1,920,000 pixels on each side, for 3,686,400,000,000 potential pixels!

The harness shows some lag when animating a zoom at near the minimum scale, but I'm guessing that's due to the work the Core Image CIAffineTile filter is doing to generate the number of tiles to in the original 30k ✕ 30k image. I would suggest using an [image pyramid](https://en.wikipedia.org/wiki/Pyramid_(image_processing)) if extreme in scales are needed.


## Improved resizing

TRMTKImageView cleantly handles resizing. Normally, when a Metal-based view is resized, it may show gaps due to display synchronization issues. I've set the background to red to highlight the issue:

![](README/Without_Padding_800.gif)


Because TRMTKImageView is synchronizing with an NSScrollView, and receiving scroll view bounds changes *after* the fact, I couldn't find a way to keep the Metal and scroll views/layers in sync. Instead, TRMTKImageView can be made about a 100 pt larger than the scrollview, allowing it to essentially prerender the edges before they're resized:

![](README/With_Padding_800.gif)


## Core Image notes

The Core Image context created by TRMTKImageView uses some WWDC20 best-practices for speeding up rendering.

To render CIImages at magnifications ≥1.0, TRMTKImageView turns on nearest neighbor sampling. When drawing images at magnifications <1.0, TRMTKImageView uses linear filtering.


## Finally

The harness contains some NSScrollView-related subclasses: TRScrollView and TRCenteringClipView

These subclasses allow for friendlier/easier NSScrollView behavior.

Enjoy!

John Balestrieri, Tinrocket

www.tinrocket.com

*Tinrocket makes original, creative, visual software for desktop and mobile. We combine our passion for art and technology to make apps that people love.*
