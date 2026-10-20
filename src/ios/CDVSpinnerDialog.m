//
//  CDVSpinnerDialog.m
//
//  Created by Domonkos Pál on 2014.01.27.
//

#import "CDVSpinnerDialog.h"

static CGFloat CDVSpinnerClamp(CGFloat value, CGFloat minimum, CGFloat maximum)
{
    return MIN(MAX(value, minimum), maximum);
}

static NSString *CDVSpinnerString(id value)
{
    if (value == nil || value == [NSNull null]) {
        return nil;
    }

    return [value isKindOfClass:[NSString class]] ? value : [value description];
}

@interface CDVSpinnerOverlayView : UIView

@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicator;
@property (nonatomic, strong, readonly) UITextView *messageView;

- (void)updateMessage:(NSString *)message
              fontSize:(CGFloat)fontSize
             textColor:(UIColor *)textColor
        overlayOpacity:(CGFloat)overlayOpacity;

@end


@implementation CDVSpinnerOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.exclusiveTouch = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        _indicator.color = [UIColor whiteColor];
        [_indicator startAnimating];
        [self addSubview:_indicator];

        _messageView = [[UITextView alloc] initWithFrame:CGRectZero];
        _messageView.backgroundColor = [UIColor clearColor];
        _messageView.editable = NO;
        _messageView.selectable = NO;
        _messageView.scrollsToTop = NO;
        _messageView.showsHorizontalScrollIndicator = NO;
        _messageView.showsVerticalScrollIndicator = NO;
        _messageView.textAlignment = NSTextAlignmentCenter;
        _messageView.textContainerInset = UIEdgeInsetsZero;
        _messageView.textContainer.lineFragmentPadding = 0.0;
        [self addSubview:_messageView];
    }
    return self;
}

- (void)updateMessage:(NSString *)message
              fontSize:(CGFloat)fontSize
             textColor:(UIColor *)textColor
        overlayOpacity:(CGFloat)overlayOpacity
{
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:CDVSpinnerClamp(overlayOpacity, 0.0, 1.0)];
    self.messageView.text = message ?: @"";
    self.messageView.textColor = textColor;
    self.messageView.font = [UIFont systemFontOfSize:CDVSpinnerClamp(fontSize, 8.0, 30.0)
                                             weight:UIFontWeightSemibold];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    CGFloat horizontalMargin = MIN(24.0, CGRectGetWidth(bounds) / 4.0);
    CGFloat verticalMargin = MIN(24.0, CGRectGetHeight(bounds) / 4.0);
    CGFloat contentWidth = MIN(560.0, MAX(0.0, CGRectGetWidth(bounds) - (horizontalMargin * 2.0)));

    [self.indicator sizeToFit];
    CGSize indicatorSize = self.indicator.bounds.size;
    BOOL hasMessage = self.messageView.text.length > 0;
    CGFloat spacing = hasMessage ? 16.0 : 0.0;
    CGFloat maximumMessageHeight = MAX(0.0, CGRectGetHeight(bounds) - (verticalMargin * 2.0) - indicatorSize.height - spacing);
    CGFloat messageHeight = 0.0;

    if (hasMessage && contentWidth > 0.0 && maximumMessageHeight > 0.0) {
        CGSize fittingSize = [self.messageView sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
        messageHeight = MIN(ceil(fittingSize.height), maximumMessageHeight);
        self.messageView.scrollEnabled = fittingSize.height > maximumMessageHeight;
        self.messageView.showsVerticalScrollIndicator = self.messageView.scrollEnabled;
    } else {
        self.messageView.scrollEnabled = NO;
        self.messageView.showsVerticalScrollIndicator = NO;
    }

    CGFloat totalHeight = indicatorSize.height + spacing + messageHeight;
    CGFloat originY = MAX(verticalMargin, CGRectGetMidY(bounds) - (totalHeight / 2.0));
    self.indicator.frame = CGRectIntegral(CGRectMake(CGRectGetMidX(bounds) - (indicatorSize.width / 2.0),
                                                     originY,
                                                     indicatorSize.width,
                                                     indicatorSize.height));
    self.messageView.hidden = !hasMessage;
    self.messageView.frame = CGRectIntegral(CGRectMake(CGRectGetMidX(bounds) - (contentWidth / 2.0),
                                                       CGRectGetMaxY(self.indicator.frame) + spacing,
                                                       contentWidth,
                                                       messageHeight));
}

@end


@interface CDVSpinnerDialog ()

@property (nonatomic, strong) CDVSpinnerOverlayView *overlay;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, copy) NSString *activeCallbackId;
@property (nonatomic, weak) UIWindowScene *attachedScene;
@property (nonatomic, assign) BOOL fixed;
@property (nonatomic, assign) BOOL cancelCallbackDelivered;
@property (nonatomic, assign) BOOL disposed;

@end


@implementation CDVSpinnerDialog

- (void)pluginInitialize
{
    [super pluginInitialize];
    self.disposed = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sceneDidDisconnect:)
                                                 name:UISceneDidDisconnectNotification
                                               object:nil];
}

- (void)show:(CDVInvokedUrlCommand *)command
{
    NSString *title = CDVSpinnerString([command argumentAtIndex:0]);
    NSString *message = CDVSpinnerString([command argumentAtIndex:1]);
    BOOL fixed = [[command argumentAtIndex:2 withDefault:@NO] boolValue];
    CGFloat overlayOpacity = [[command argumentAtIndex:3 withDefault:@0.35] doubleValue];
    CGFloat red = [[command argumentAtIndex:4 withDefault:@1.0] doubleValue];
    CGFloat green = [[command argumentAtIndex:5 withDefault:@1.0] doubleValue];
    CGFloat blue = [[command argumentAtIndex:6 withDefault:@1.0] doubleValue];
    CGFloat fontSize = [[command argumentAtIndex:7 withDefault:@16.0] doubleValue];
    id callbackFlag = [command argumentAtIndex:8 withDefault:nil];
    BOOL hasCancelCallback = callbackFlag == nil ? fixed : [callbackFlag boolValue];
    NSString *commandCallbackId = [command.callbackId copy];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.disposed) {
            return;
        }

        [self releaseActiveCallback];

        NSString *hostError = nil;
        UIView *hostView = [self hostViewWithError:&hostError];
        if (hostView == nil) {
            [self removeOverlay];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:hostError ?: @"SpinnerDialog could not find a valid Cordova host view."];
            [self.commandDelegate sendPluginResult:result callbackId:commandCallbackId];
            return;
        }

        if (self.overlay == nil) {
            self.overlay = [[CDVSpinnerOverlayView alloc] initWithFrame:hostView.bounds];
            self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
            self.tapRecognizer.cancelsTouchesInView = NO;
            [self.overlay addGestureRecognizer:self.tapRecognizer];
        }

        if (self.overlay.superview != hostView) {
            [self.overlay removeFromSuperview];
            self.overlay.frame = hostView.bounds;
            [hostView addSubview:self.overlay];
        } else {
            self.overlay.frame = hostView.bounds;
            [hostView bringSubviewToFront:self.overlay];
        }

        NSString *displayMessage = message ?: title;
        UIColor *textColor = [UIColor colorWithRed:CDVSpinnerClamp(red, 0.0, 1.0)
                                             green:CDVSpinnerClamp(green, 0.0, 1.0)
                                              blue:CDVSpinnerClamp(blue, 0.0, 1.0)
                                             alpha:1.0];
        [self.overlay updateMessage:displayMessage
                           fontSize:fontSize
                          textColor:textColor
                     overlayOpacity:overlayOpacity];
        [self.overlay.indicator startAnimating];

        self.fixed = fixed;
        self.cancelCallbackDelivered = NO;
        self.attachedScene = hostView.window.windowScene;

        if (hasCancelCallback) {
            self.activeCallbackId = commandCallbackId;
            CDVPluginResult *pendingResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
            [pendingResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pendingResult callbackId:self.activeCallbackId];
        } else {
            CDVPluginResult *completeResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
            [completeResult setKeepCallbackAsBool:NO];
            [self.commandDelegate sendPluginResult:completeResult callbackId:commandCallbackId];
        }
    });
}

- (void)hide:(CDVInvokedUrlCommand *)command
{
    NSString *commandCallbackId = [command.callbackId copy];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.disposed) {
            [self cleanup];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:commandCallbackId];
        }
    });
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture
{
    if (gesture.state != UIGestureRecognizerStateEnded || self.disposed) {
        return;
    }

    if (self.activeCallbackId.length > 0 && !self.cancelCallbackDelivered) {
        self.cancelCallbackDelivered = YES;
        NSString *callbackId = self.activeCallbackId;
        self.activeCallbackId = nil;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [result setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }

    if (!self.fixed) {
        [self cleanup];
    }
}

- (UIView *)hostViewWithError:(NSString **)error
{
    UIViewController *viewController = self.viewController;
    if (viewController == nil) {
        if (error != NULL) {
            *error = @"SpinnerDialog could not access Cordova's view controller.";
        }
        return nil;
    }

    UIView *hostView = viewController.view;
    if (hostView == nil || hostView.window == nil || CGRectIsEmpty(hostView.bounds)) {
        if (error != NULL) {
            *error = @"SpinnerDialog could not find a visible Cordova host view.";
        }
        return nil;
    }

    UIWindowScene *windowScene = hostView.window.windowScene;
    if (windowScene == nil || windowScene.activationState == UISceneActivationStateUnattached) {
        if (error != NULL) {
            *error = @"SpinnerDialog's Cordova host view is not attached to an active scene.";
        }
        return nil;
    }

    return hostView;
}

- (void)releaseActiveCallback
{
    if (self.activeCallbackId.length == 0) {
        return;
    }

    NSString *callbackId = self.activeCallbackId;
    self.activeCallbackId = nil;
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [result setKeepCallbackAsBool:NO];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)removeOverlay
{
    if (self.tapRecognizer != nil) {
        [self.overlay removeGestureRecognizer:self.tapRecognizer];
        [self.tapRecognizer removeTarget:self action:@selector(handleTapGesture:)];
    }

    [self.overlay.indicator stopAnimating];
    [self.overlay removeFromSuperview];
    self.tapRecognizer = nil;
    self.overlay = nil;
    self.attachedScene = nil;
    self.fixed = NO;
    self.cancelCallbackDelivered = NO;
}

- (void)cleanup
{
    [self releaseActiveCallback];
    [self removeOverlay];
}

- (void)sceneDidDisconnect:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.object == self.attachedScene) {
            [self cleanup];
        }
    });
}

- (void)onReset
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanup];
    });
}

- (void)dispose
{
    void (^disposeOnMain)(void) = ^{
        self.disposed = YES;
        [self cleanup];
    };

    if ([NSThread isMainThread]) {
        disposeOnMain();
    } else {
        dispatch_sync(dispatch_get_main_queue(), disposeOnMain);
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UISceneDidDisconnectNotification
                                                  object:nil];
    [super dispose];
}

@end
