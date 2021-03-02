#import "BVLinearGradientLayer.h"

#import <UIKit/UIKit.h>

@implementation BVLinearGradientLayer

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.needsDisplayOnBoundsChange = YES;
        self.masksToBounds = YES;
        _startPoint = CGPointMake(0.5, 0.0);
        _endPoint = CGPointMake(0.5, 1.0);
        _angleCenter = CGPointMake(0.5, 0.5);
        _angle = 45.0;
    }

    return self;
}

- (void)setColors:(NSArray<id> *)colors
{
    _colors = colors;
    [self setNeedsDisplay];
}

- (void)setLocations:(NSArray<NSNumber *> *)locations
{
    _locations = locations;
    [self setNeedsDisplay];
}

- (void)setStartPoint:(CGPoint)startPoint
{
    _startPoint = startPoint;
    [self setNeedsDisplay];
}

- (void)setEndPoint:(CGPoint)endPoint
{
    _endPoint = endPoint;
    [self setNeedsDisplay];
}

- (void)display {
    [super display];

    BOOL hasAlpha = NO;

    for (NSInteger i = 0; i < self.colors.count; i++) {
        hasAlpha = hasAlpha || CGColorGetAlpha(self.colors[i].CGColor) < 1.0;
    }

    UIGraphicsBeginImageContextWithOptions(self.bounds.size, !hasAlpha, 0.0);
    CGContextRef ref = UIGraphicsGetCurrentContext();
    [self drawInContext:ref];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    self.contents = (__bridge id _Nullable)(image.CGImage);
    self.contentsScale = image.scale;

    UIGraphicsEndImageContext();
}

- (void)setUseAngle:(BOOL)useAngle
{
    _useAngle = useAngle;
    [self setNeedsDisplay];
}

- (void)setAngleCenter:(CGPoint)angleCenter
{
    _angleCenter = angleCenter;
    [self setNeedsDisplay];
}

- (void)setAngle:(CGFloat)angle
{
    _angle = angle - (floor(angle / 360) * 360);
    [self setNeedsDisplay];
}

- (CGSize)calculateGradientLocationWithAngle:(CGFloat)angle
{
    CGFloat angleRad = (angle - 90) * (M_PI / 180);
    CGFloat length = sqrt(2);

    return CGSizeMake(cos(angleRad) * length, sin(angleRad) * length);
}

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];

    CGContextSaveGState(ctx);

    CGSize size = self.bounds.size;
    if (!self.colors || self.colors.count == 0 || size.width == 0.0 || size.height == 0.0)
        return;


    CGFloat *locations = nil;

    locations = malloc(sizeof(CGFloat) * self.colors.count);

    for (NSInteger i = 0; i < self.colors.count; i++)
    {
        if (self.locations.count > i)
        {
            locations[i] = self.locations[i].floatValue;
        }
        else
        {
            locations[i] = (1.0 / (self.colors.count - 1)) * i;
        }
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:self.colors.count];
    for (UIColor *color in self.colors) {
        [colors addObject:(id)color.CGColor];
    }

    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);

    free(locations);

    CGPoint start = self.startPoint, end = self.endPoint;
    CGPoint startPx;
    CGPoint endPx;

    if (_useAngle)
    {
      if (_angle >= 0 && _angle <= 90) {
        CGFloat degree = (_angle) * M_PI / 180;
        CGFloat koef = (size.width * _angleCenter.x - size.height * _angleCenter.y * sin(degree) / cos(degree)) * cos(degree);
        CGFloat dx = koef * cos(degree);
        CGFloat dy = koef * sin(degree);
        startPx = CGPointMake(dx, size.height + dy);
        endPx = CGPointMake(size.width - dx, -dy);
      } else if (_angle > 90  && _angle <= 180) {
        CGFloat degree = (90 - (_angle - 90)) * M_PI / 180;
        CGFloat koef = (size.width * _angleCenter.x - size.height * _angleCenter.y * sin(degree) / cos(degree)) * cos(degree);
        CGFloat dx = koef * cos(degree);
        CGFloat dy = koef * sin(degree);
        startPx = CGPointMake(dx, -dy);
        endPx = CGPointMake(size.width - dx, size.height + dy);
      } else if (_angle > 180 && _angle <= 270) {
        CGFloat degree = (_angle - 180) * M_PI / 180;
        CGFloat koef = (size.width * _angleCenter.x - size.height * _angleCenter.y * sin(degree) / cos(degree)) * cos(degree);
        CGFloat dx = koef * cos(degree);
        CGFloat dy = koef * sin(degree);
        startPx = CGPointMake(size.width - dx, -dy);
        endPx = CGPointMake(dx, size.height + dy);
      } else if (_angle > 270 && _angle <= 360) {
        CGFloat degree = (180 - (_angle - 180)) * M_PI / 180;
        CGFloat koef = (size.width * _angleCenter.x - size.height * _angleCenter.y * sin(degree) / cos(degree)) * cos(degree);
        CGFloat dx = koef * cos(degree);
        CGFloat dy = koef * sin(degree);
        startPx = CGPointMake(size.width - dx, size.height + dy);
        endPx = CGPointMake(dx, -dy);
      }
    } else {
      startPx = CGPointMake(start.x * size.width, start.y * size.height);
      endPx = CGPointMake(end.x * size.width, end.y * size.height);
    }

    CGContextDrawLinearGradient(ctx, gradient,
                                startPx,
                                endPx,
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    CGContextRestoreGState(ctx);
}

@end
