
#import "KSLabel.h"

@implementation KSLabel

-(id)initWithFrame:(CGRect)frame {
  
	if (self = [super initWithFrame:frame]) {
		outlineColor = nil;
    outlineWidth = 0;
	}
  
  return self;
}

- (void)drawTextInRect:(CGRect)rect {
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetTextDrawingMode(context, kCGTextFill);
	
	// Draw the text without an outline
	[super drawTextInRect:rect];
	
	if (outlineColor && outlineWidth) {
		// Create a mask from the text
		CGImageRef alphaMask = CGBitmapContextCreateImage(context);
		
		// Outline width
		CGContextSetLineWidth(context, outlineWidth);
		CGContextSetLineJoin(context, kCGLineJoinRound);
		
		// Set the drawing method to stroke
		CGContextSetTextDrawingMode(context, kCGTextStroke);
		
    // do not seem to work
    //CGContextSetShouldAntialias(context, YES);
    //CGContextSetAllowsAntialiasing(context, YES);
    //CGContextSetShouldSmoothFonts(context, YES);
    //CGContextSetAllowsFontSmoothing(context, YES);
    
    UIColor* previousColor = self.textColor;
    
		// Outline color
		self.textColor = outlineColor;
		
		[super drawTextInRect:rect];
		
		// Draw the saved image over the outline
		// and invert everything because CoreGraphics works with an inverted coordinate system
		CGContextTranslateCTM(context, 0, rect.size.height);
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextDrawImage(context, rect, alphaMask);
		
		// Clean up because ARC doesnt handle CG
		CGImageRelease(alphaMask);
    
    self.textColor = previousColor;
	}
}

@synthesize outlineColor, outlineWidth;

@end
