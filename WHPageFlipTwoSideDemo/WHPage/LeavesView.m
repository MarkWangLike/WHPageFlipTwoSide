#import "LeavesView.h"
#import "LeavesCache.h"
#pragma mark Private interface

@interface LeavesView () 

@property(nonatomic, readonly)CALayer *topPage, *topPageOverlay, *topPageReverse, *topPageReverseImage,
*topPageReverseOverlay, *bottomPage, *leftPage, *leftPageOverlay;

@property(nonatomic, readonly)CAGradientLayer *topPageShadow, *topPageReverseShading, *bottomPageShadow;

@property(nonatomic, assign)NSUInteger numberOfPages,numberOfVisiblePages;

@property(nonatomic, assign)CGFloat leafEdge;

@property(nonatomic, assign)CGSize pageSize;

@property(nonatomic, assign)CGPoint touchBeganPoint;

@property(nonatomic, assign)CGRect nextPageRect, prevPageRect;

@property(nonatomic, assign)BOOL touchIsActive, interactionLocked;

@property (readonly) LeavesCache *pageCache;

@end

CGFloat distance(CGPoint a, CGPoint b);



#pragma mark -
#pragma mark Implementation

@implementation LeavesView

- (void) setUpLayers {
	self.clipsToBounds = YES;
    
	_topPage = [[CALayer alloc] init];
	_topPage.masksToBounds = YES;
	_topPage.contentsGravity = kCAGravityLeft;
	_topPage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	_topPageOverlay = [[CALayer alloc] init];
	_topPageOverlay.backgroundColor = [[[UIColor blackColor] colorWithAlphaComponent:0.2] CGColor];
	
	_topPageShadow = [[CAGradientLayer alloc] init];
	_topPageShadow.colors = [NSArray arrayWithObjects:
							(id)[[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor],
							(id)[[UIColor clearColor] CGColor],
							nil];
	_topPageShadow.startPoint = CGPointMake(1,0.5);
	_topPageShadow.endPoint = CGPointMake(0,0.5);
	
	_topPageReverse = [[CALayer alloc] init];
	_topPageReverse.backgroundColor = [[UIColor whiteColor] CGColor];
	_topPageReverse.masksToBounds = YES;
	
	_topPageReverseImage = [[CALayer alloc] init];
	_topPageReverseImage.masksToBounds = YES;
	
	_topPageReverseOverlay = [[CALayer alloc] init];
	
	_topPageReverseShading = [[CAGradientLayer alloc] init];
	_topPageReverseShading.colors = [NSArray arrayWithObjects:
									(id)[[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor],
									(id)[[UIColor clearColor] CGColor],
									nil];
	_topPageReverseShading.startPoint = CGPointMake(1,0.5);
	_topPageReverseShading.endPoint = CGPointMake(0,0.5);
	
	_bottomPage = [[CALayer alloc] init];
	_bottomPage.backgroundColor = [[UIColor whiteColor] CGColor];
	_bottomPage.masksToBounds = YES;
	
	_bottomPageShadow = [[CAGradientLayer alloc] init];
	_bottomPageShadow.colors = [NSArray arrayWithObjects:
							   (id)[[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor],
							   (id)[[UIColor clearColor] CGColor],
							   nil];
	_bottomPageShadow.startPoint = CGPointMake(0,0.5);
	_bottomPageShadow.endPoint = CGPointMake(1,0.5);
	
	[_topPage addSublayer:_topPageOverlay];
	[_topPageReverse addSublayer:_topPageReverseImage];
	[_topPageReverse addSublayer:_topPageReverseOverlay];
	[_topPageReverse addSublayer:_topPageReverseShading];
	[_bottomPage addSublayer:_bottomPageShadow];

    // Setup for the left page in two-page mode
    _leftPage = [[CALayer alloc] init];
	_leftPage.masksToBounds = YES;
	_leftPage.contentsGravity = kCAGravityLeft;
	_leftPage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	_leftPageOverlay = [[CALayer alloc] init];
	_leftPageOverlay.backgroundColor = [[[UIColor blackColor] colorWithAlphaComponent:0.2] CGColor];
		
	[_leftPage addSublayer:_leftPageOverlay];
    
	[self.layer addSublayer:_leftPage];
	[self.layer addSublayer:_bottomPage];
	[self.layer addSublayer:_topPage];
	[self.layer addSublayer:_topPageReverse];
    [self.layer addSublayer:_topPageShadow];
    
    [self setUpLayersForViewingMode];
	
	self.leafEdge = 1.0;
}


- (void)setUpLayersForViewingMode {
    if (self.mode == LeavesViewModeSinglePage) {
        _topPageReverseImage.contentsGravity = kCAGravityRight;
        _topPageReverseOverlay.backgroundColor = [[[UIColor whiteColor] colorWithAlphaComponent:0.8] CGColor];
        _topPageReverseImage.transform = CATransform3DMakeScale(-1, 1, 1);
    } else {
        _topPageReverseImage.contentsGravity = kCAGravityLeft;
        _topPageReverseOverlay.backgroundColor = [[[UIColor whiteColor] colorWithAlphaComponent:0.0] CGColor];
        _topPageReverseImage.transform = CATransform3DMakeScale(1, 1, 1);
    }
}



#pragma mark -
#pragma mark Initialization and teardown

- (void) initialize {
	_mode = LeavesViewModeSinglePage;
    _numberOfVisiblePages = 1;
	_backgroundRendering = NO;
    
    CGSize cachePageSize = self.bounds.size;
    if (_mode == LeavesViewModeFacingPages) {
        cachePageSize = CGSizeMake(self.bounds.size.width / 2.0f, self.bounds.size.height);
    }
	_pageCache = [[LeavesCache alloc] initWithPageSize:cachePageSize];
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self setUpLayers];
		[self initialize];
    }
    return self;
}


- (void) awakeFromNib {
	[super awakeFromNib];
	[self setUpLayers];
	[self initialize];
}





#pragma mark -
#pragma mark Image loading

- (void) reloadData {
	[_pageCache flush];
	_numberOfPages = [_pageCache.dataSource numberOfPagesInLeavesView:self];
	self.currentPageIndex = 0;
}


- (void) getImages {
    if (self.mode == LeavesViewModeSinglePage) 
    {
        if (_currentPageIndex < _numberOfPages) {
            if (_currentPageIndex > 0 && _backgroundRendering) {
                [_pageCache precacheImageForPageIndex:_currentPageIndex-1];
            }
            _topPage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex];
            _leftPage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex];
            if (_currentPageIndex < _numberOfPages - 1) {
                _topPageReverseImage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex];
                _bottomPage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex + 1];
            }
            [_pageCache minimizeToPageIndex:_currentPageIndex viewMode:self.mode];
        } else {
            _topPage.contents = nil;
            _topPageReverseImage.contents = nil;
            _bottomPage.contents = nil;
            
            _leftPage.contents = nil;
        }
    }
    else
    {
        if (_currentPageIndex <= _numberOfPages) {
            if (_currentPageIndex > 1 && _backgroundRendering) {
                [_pageCache precacheImageForPageIndex:_currentPageIndex-2];
            }
            if (_currentPageIndex > 2 && _backgroundRendering) {
                [_pageCache precacheImageForPageIndex:_currentPageIndex-2];
            }
            
            _topPage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex];
            if (_currentPageIndex > 0) {
                _leftPage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex-1];
            } else {
                _leftPage.contents = nil;
            }
            
            if (_currentPageIndex < _numberOfPages - 1) {
                _topPageReverseImage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex + 1];
                _bottomPage.contents = (id)[_pageCache cachedImageForPageIndex:_currentPageIndex + 2];
            }
            [_pageCache minimizeToPageIndex:_currentPageIndex viewMode:self.mode];
        } else {
            _topPage.contents = nil;
            _topPageReverseImage.contents = nil;
            _bottomPage.contents = nil;
            
            _leftPage.contents = nil;
        }
    }
}



#pragma mark -
#pragma mark Layout

- (void) setLayerFrames {
    CGRect rightPageBoundsRect = self.layer.bounds;
    CGRect leftHalf, rightHalf;
    CGRectDivide(rightPageBoundsRect, &leftHalf, &rightHalf, CGRectGetWidth(rightPageBoundsRect) / 2.0f, CGRectMinXEdge);
    if (self.mode == LeavesViewModeFacingPages) {
        rightPageBoundsRect = rightHalf;
    }
    
	_topPage.frame = CGRectMake(rightPageBoundsRect.origin.x, 
							   rightPageBoundsRect.origin.y, 
							   _leafEdge * rightPageBoundsRect.size.width,
							   rightPageBoundsRect.size.height);
	_topPageReverse.frame = CGRectMake(rightPageBoundsRect.origin.x + (2*_leafEdge-1) * rightPageBoundsRect.size.width, 
									  rightPageBoundsRect.origin.y, 
									  (1-_leafEdge) * rightPageBoundsRect.size.width, 
									  rightPageBoundsRect.size.height);
	_bottomPage.frame = rightPageBoundsRect;
	_topPageShadow.frame = CGRectMake(_topPageReverse.frame.origin.x - 40, 
									 0, 
									 40, 
									 _bottomPage.bounds.size.height);
	_topPageReverseImage.frame = _topPageReverse.bounds;
	_topPageReverseOverlay.frame = _topPageReverse.bounds;
	_topPageReverseShading.frame = CGRectMake(_topPageReverse.bounds.size.width - 50, 
											 0, 
											 50 + 1, 
											 _topPageReverse.bounds.size.height);
	_bottomPageShadow.frame = CGRectMake(_leafEdge * rightPageBoundsRect.size.width, 
										0, 
										40, 
										_bottomPage.bounds.size.height);
	_topPageOverlay.frame = _topPage.bounds;
    
    
    
    if (self.mode == LeavesViewModeSinglePage) {
        _leftPage.hidden = YES;
        _leftPageOverlay.hidden = _leftPage.hidden;
    } else {
        _leftPage.hidden = NO;
        _leftPageOverlay.hidden = _leftPage.hidden;
        _leftPage.frame = CGRectMake(leftHalf.origin.x, 
                                   leftHalf.origin.y, 
                                   leftHalf.size.width, 
                                   leftHalf.size.height);
        _leftPageOverlay.frame = _leftPage.bounds;
        
    }
}

- (void) willTurnToPageAtIndex:(NSUInteger)index {
	if ([self.delegate respondsToSelector:@selector(leavesView:willTurnToPageAtIndex:)])
		[self.delegate leavesView:self willTurnToPageAtIndex:index];
}

- (void) didTurnToPageAtIndex:(NSUInteger)index {
	if ([self.delegate respondsToSelector:@selector(leavesView:didTurnToPageAtIndex:)])
		[self.delegate leavesView:self didTurnToPageAtIndex:index];
}

- (void) didTurnPageBackward {
	_interactionLocked = NO;
	[self didTurnToPageAtIndex:_currentPageIndex];
}

- (void) didTurnPageForward {
	_interactionLocked = NO;
	self.currentPageIndex = self.currentPageIndex + _numberOfVisiblePages;
	[self didTurnToPageAtIndex:_currentPageIndex];
}

- (BOOL) hasPrevPage {
    return self.currentPageIndex > (_numberOfVisiblePages - 1);
}

- (BOOL) hasNextPage {
	if (self.mode == LeavesViewModeSinglePage) {
        return self.currentPageIndex < _numberOfPages - 1;
    } else {
        return  ((self.currentPageIndex % 2 == 0) && (self.currentPageIndex < _numberOfPages - 1)) ||
                ((self.currentPageIndex % 2 != 0) && (self.currentPageIndex < _numberOfPages - 2));
    }
}

- (BOOL) touchedNextPage {
	return CGRectContainsPoint(_nextPageRect, _touchBeganPoint);
}

- (BOOL) touchedPrevPage {
	return CGRectContainsPoint(_prevPageRect, _touchBeganPoint);
}

- (CGFloat) dragThreshold {
	// Magic empirical number
	return 10;
}

- (CGFloat) targetWidth {
	// Magic empirical formula
	return MAX(28, self.bounds.size.width / 5);
}

#pragma mark -
#pragma mark accessors

- (id<LeavesViewDataSource>) dataSource {
	return _pageCache.dataSource;
}

- (void) setDataSource:(id<LeavesViewDataSource>)value {
	_pageCache.dataSource = value;
}

- (void) setLeafEdge:(CGFloat)aLeafEdge {
	_leafEdge = aLeafEdge;
	
    CGFloat pageOpacity = MIN(1.0, 4*(1-_leafEdge));
    
    _topPageShadow.opacity        = pageOpacity;
	_bottomPageShadow.opacity     = pageOpacity;
	_topPageOverlay.opacity       = pageOpacity;
	_leftPageOverlay.opacity   = pageOpacity;

    [self setLayerFrames];
}


- (void) setCurrentPageIndex:(NSUInteger)aCurrentPageIndex {
    _currentPageIndex = aCurrentPageIndex;
	if (self.mode == LeavesViewModeFacingPages && aCurrentPageIndex % 2 != 0) {
        _currentPageIndex = aCurrentPageIndex + 1;
    }
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[self getImages];
	
	self.leafEdge = 1;
	
	[CATransaction commit];
}


- (void) setMode:(LeavesViewMode)newMode
{
    _mode = newMode;
    
    if (_mode == LeavesViewModeSinglePage) {
        _numberOfVisiblePages = 1;
        if (self.currentPageIndex > _numberOfPages - 1) {
            self.currentPageIndex = _numberOfPages - 1;
        }
        
    } else {
        _numberOfVisiblePages = 2;
        if (self.currentPageIndex % 2 != 0) {
            self.currentPageIndex++;
        }
    }

    [self setUpLayersForViewingMode];
    [self setNeedsLayout];
}



#pragma mark -
#pragma mark UIView methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_interactionLocked)
		return;
	
	UITouch *touch = [event.allTouches anyObject];
	_touchBeganPoint = [touch locationInView:self];
	
	if ([self touchedPrevPage] && [self hasPrevPage]) {		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];

        self.currentPageIndex = self.currentPageIndex - _numberOfVisiblePages;
        self.leafEdge = 0.0;
		[CATransaction commit];
		_touchIsActive = YES;
	} 
	else if ([self touchedNextPage] && [self hasNextPage])
		_touchIsActive = YES;
	
	else 
		_touchIsActive = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!_touchIsActive)
		return;
	UITouch *touch = [event.allTouches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.07]
					 forKey:kCATransactionAnimationDuration];
	self.leafEdge = touchPoint.x / self.bounds.size.width;
	[CATransaction commit];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!_touchIsActive)
		return;
	_touchIsActive = NO;
	
	UITouch *touch = [event.allTouches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	BOOL dragged = distance(touchPoint, _touchBeganPoint) > [self dragThreshold];
	
	[CATransaction begin];
	float duration;
	if ((dragged && self.leafEdge < 0.5) || (!dragged && [self touchedNextPage])) {
        [self willTurnToPageAtIndex:_currentPageIndex + _numberOfVisiblePages];
		self.leafEdge = 0;
		duration = _leafEdge;
		_interactionLocked = YES;
		if (_currentPageIndex+2 < _numberOfPages && _backgroundRendering)
			[_pageCache precacheImageForPageIndex:_currentPageIndex+2];
		[self performSelector:@selector(didTurnPageForward)
				   withObject:nil 
				   afterDelay:duration + 0.25];
	}
	else {
		[self willTurnToPageAtIndex:_currentPageIndex];
		self.leafEdge = 1.0;
		duration = 1 - _leafEdge;
		_interactionLocked = YES;
		[self performSelector:@selector(didTurnPageBackward)
				   withObject:nil 
				   afterDelay:duration + 0.25];
	}
	[CATransaction setValue:[NSNumber numberWithFloat:duration]
					 forKey:kCATransactionAnimationDuration];
	[CATransaction commit];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	
    
	CGSize desiredPageSize = self.bounds.size;
    if (self.mode == LeavesViewModeFacingPages) {
        desiredPageSize = CGSizeMake(self.bounds.size.width/2.0f, self.bounds.size.height);
    }
    
	if (!CGSizeEqualToSize(_pageSize, desiredPageSize)) {
		_pageSize = desiredPageSize;
		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		[self setLayerFrames];
		[CATransaction commit];
		_pageCache.pageSize = _pageSize;
		[self getImages];
		
		CGFloat touchRectsWidth = self.bounds.size.width / 7;
		_nextPageRect = CGRectMake(self.bounds.size.width - touchRectsWidth,
								  0,
								  touchRectsWidth,
								  self.bounds.size.height);
		_prevPageRect = CGRectMake(0,
								  0,
								  touchRectsWidth,
								  self.bounds.size.height);
	}
}

@end

CGFloat distance(CGPoint a, CGPoint b) {
	return sqrtf(powf(a.x-b.x, 2) + powf(a.y-b.y, 2));
}
