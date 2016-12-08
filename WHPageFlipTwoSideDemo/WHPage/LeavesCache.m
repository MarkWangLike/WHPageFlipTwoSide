#import "LeavesCache.h"
@interface LeavesCache ()

@property (readonly) NSMutableDictionary *pageCache;

@end

@implementation LeavesCache

- (id) initWithPageSize:(CGSize)aPageSize
{
	if ([super init]) {
		_pageSize = aPageSize;
		_pageCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (CGImageRef) imageForPageIndex:(NSUInteger)pageIndex {
    if (CGSizeEqualToSize(self.pageSize, CGSizeZero))
        return NULL;
    UIGraphicsBeginImageContext(CGSizeMake(_pageSize.width, _pageSize.height));
    CGContextRef contex = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(contex, 0, _pageSize.height);
    CGContextScaleCTM(contex, 1.0, -1.0);
   [_dataSource renderPageAtIndex:pageIndex inContext:contex];
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return returnImage.CGImage;

}

- (CGImageRef) cachedImageForPageIndex:(NSUInteger)pageIndex {
	NSNumber *pageIndexNumber = [NSNumber numberWithInteger:pageIndex];
	UIImage *pageImage;
	@synchronized (self.pageCache) {
		pageImage = [self.pageCache objectForKey:pageIndexNumber];
	}
	if (!pageImage) {
		CGImageRef pageCGImage = [self imageForPageIndex:pageIndex];
		pageImage = [UIImage imageWithCGImage:pageCGImage];
		@synchronized (self.pageCache) {
//			[self.pageCache setObject:pageImage forKey:pageIndexNumber];
		}
	}
	return pageImage.CGImage;
}

- (void) precacheImageForPageIndexNumber:(NSNumber *)pageIndexNumber {
    @autoreleasepool {
        
        [self cachedImageForPageIndex:[pageIndexNumber intValue]];
    }

}

- (void) precacheImageForPageIndex:(NSUInteger)pageIndex {
	[self performSelectorInBackground:@selector(precacheImageForPageIndexNumber:)
						   withObject:[NSNumber numberWithInteger:pageIndex]];
}

- (void) minimizeToPageIndex:(NSUInteger)pageIndex viewMode:(LeavesViewMode)viewMode {
	/* Uncache all pages except previous, current, and next. */
	@synchronized (self.pageCache) {
        int cutoffValueFromPageIndex = 2;
        if (viewMode == LeavesViewModeFacingPages) {
            cutoffValueFromPageIndex = 3;
        }
		for (NSNumber *key in [self.pageCache allKeys])
			if (ABS([key intValue] - (int)pageIndex) > cutoffValueFromPageIndex)
				[self.pageCache removeObjectForKey:key];
	}
}

- (void) flush {
	@synchronized (self.pageCache) {
		[self.pageCache removeAllObjects];
	}
}

#pragma mark accessors
- (void) setPageSize:(CGSize)value {
	_pageSize = value;
	[self flush];
}

@end
