//
//  ZPShadowView.m
//  ZPCode
//
//  Created by xinzhipeng on 2017/9/8.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ZPShadowView.h"

@interface ZPShadowView()<CAAnimationDelegate>

@property (nonatomic, strong) UIImageView *lineView;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ZPShadowView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        // 图片下方附上
        self.lineView  = [[UIImageView alloc] init];
        self.lineView.image = [UIImage imageNamed:@"line"];
        [self addSubview:self.lineView];
    }
    return self;
}


//- (void)stopTimer
//{
//    [_timer invalidate];
//    _timer = nil;
//}

-(void)layoutSubviews{
    [super layoutSubviews];
//    if (!_timer) {
//        [self playAnimation];
//        /* 自动播放 */
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(playAnimation) userInfo:nil repeats:YES];
//    }
}
//-(void)playAnimation{
//    
//    [UIView animateWithDuration:2.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
//        
//        self.lineView .frame = CGRectMake((self.frame.size.width - self.showSize.width) / 2, (self.frame.size.height + self.showSize.height) / 2, self.showSize.width, 2);
//        
//    } completion:^(BOOL finished) {
//        self.lineView .frame = CGRectMake((self.frame.size.width - self.showSize.width) / 2, (self.frame.size.height - self.showSize.height) / 2, self.showSize.width, 2);
//    }];
//}
-(void)setShowSize:(CGSize)showSize{
    _showSize = showSize;
    self.lineView .frame = CGRectMake((self.frame.size.width - self.showSize.width) / 2, (self.frame.size.height - self.showSize.height) / 2, self.showSize.width, 2);
    [self addAnimationAboutScan];
}
-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    //整体颜色
    CGContextSetRGBFillColor(contextRef, 0.15, 0.15, 0.15, 0.6);
    CGContextFillRect(contextRef, rect);
    //中间清空矩形框
    CGRect clearDrawRect = CGRectMake((rect.size.width - self.showSize.width) / 2, (rect.size.height - self.showSize.height) / 2, self.showSize.width, self.showSize.height);
    CGContextClearRect(contextRef, clearDrawRect);

    //边框
    CGContextStrokeRect(contextRef, clearDrawRect);
    CGContextSetRGBStrokeColor(contextRef, 1, 1, 1, 1);  //颜色
    CGContextSetLineWidth(contextRef, 0.5);             //线宽
    CGContextAddRect(contextRef, clearDrawRect);       //矩形
    CGContextStrokePath(contextRef);
    
    [self addCornerLineWithContext:contextRef rect:clearDrawRect];
    
}

- (void)addCornerLineWithContext: (CGContextRef)contextRef rect: (CGRect)rect{
    
    CGFloat cornerW = 3.0;
    CGFloat cornerL = 15.0;
    //线宽
    CGContextSetLineWidth(contextRef, cornerW);
    //线颜色(绿色)
    CGContextSetRGBStrokeColor(contextRef, 83 / 255.0, 239 / 255.0, 111 / 255.0, 1);
    
    //左上角
    CGPoint poinsTopLeftA[] = {CGPointMake(rect.origin.x + cornerW  /2, rect.origin.y),
        CGPointMake(rect.origin.x + cornerW / 2, rect.origin.y + cornerL)};
    
    CGPoint poinsTopLeftB[] = {CGPointMake(rect.origin.x, rect.origin.y + cornerW / 2),
        CGPointMake(rect.origin.x + cornerL, rect.origin.y + cornerW / 2)};
    
    [self addLine:poinsTopLeftA pointB:poinsTopLeftB ctx:contextRef];
    
    
    //左下角
    CGPoint poinsBottomLeftA[] = {CGPointMake(rect.origin.x + cornerW / 2, rect.origin.y + rect.size.height - cornerL),
        CGPointMake(rect.origin.x + cornerW / 2, rect.origin.y + rect.size.height)};
    
    CGPoint poinsBottomLeftB[] = {CGPointMake(rect.origin.x, rect.origin.y + rect.size.height - cornerW / 2),
        CGPointMake(rect.origin.x + cornerL, rect.origin.y + rect.size.height - cornerW / 2)};
    
    [self addLine:poinsBottomLeftA pointB:poinsBottomLeftB ctx:contextRef];
    
    
    //右上角
    CGPoint poinsTopRightA[] = {CGPointMake(rect.origin.x+ rect.size.width - cornerL, rect.origin.y + cornerW / 2),
        CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + cornerW / 2 )};
    
    CGPoint poinsTopRightB[] = {CGPointMake(rect.origin.x+ rect.size.width - cornerW / 2, rect.origin.y),
        CGPointMake(rect.origin.x + rect.size.width- cornerW / 2, rect.origin.y + cornerL)};
    
    [self addLine:poinsTopRightA pointB:poinsTopRightB ctx:contextRef];
    
    //右下角
    CGPoint poinsBottomRightA[] = {CGPointMake(rect.origin.x+ rect.size.width - cornerW / 2, rect.origin.y+rect.size.height - cornerL),
        CGPointMake(rect.origin.x- cornerW / 2 + rect.size.width, rect.origin.y +rect.size.height )};
    
    CGPoint poinsBottomRightB[] = {CGPointMake(rect.origin.x+ rect.size.width - cornerL, rect.origin.y + rect.size.height - cornerW / 2),
        CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - cornerW / 2 )};
    
    [self addLine:poinsBottomRightA pointB:poinsBottomRightB ctx:contextRef];

    CGContextStrokePath(contextRef);
    
}

- (void)addLine:(CGPoint[])pointA pointB:(CGPoint[])pointB ctx:(CGContextRef)ctx {
    
    CGContextAddLines(ctx, pointA, 2);
    CGContextAddLines(ctx, pointB, 2);
}

//NSTimer不是太好,手机有时候会卡顿, 用CABasicAnimation动画
-(void)addAnimationAboutScan{
    self.lineView.hidden = NO;
    CABasicAnimation *animation = [self moveYTime:2.5 fromY:[NSNumber numberWithFloat:0] toY:[NSNumber numberWithFloat:(self.showSize.height-1)] rep:OPEN_MAX];
    [self.lineView.layer addAnimation:animation forKey:@"LineAnimation"];
}

- (CABasicAnimation *)moveYTime:(float)time fromY:(NSNumber *)fromY toY:(NSNumber *)toY rep:(int)rep{
    
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationMove setFromValue:fromY];
    [animationMove setToValue:toY];
    animationMove.duration = time;
    animationMove.delegate = self;
    animationMove.repeatCount  = rep;
    animationMove.fillMode = kCAFillModeForwards;
    animationMove.removedOnCompletion = NO;
    animationMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return animationMove;
}

- (void)removeAnimationAboutScan{
    [self.lineView.layer removeAnimationForKey:@"LineAnimation"];
    self.lineView.hidden = YES;
}


@end











