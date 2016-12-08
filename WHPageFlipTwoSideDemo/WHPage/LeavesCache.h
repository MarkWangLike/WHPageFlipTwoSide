#import <Foundation/Foundation.h>
#import "LeavesView.h"

@protocol LeavesViewDataSource;

@interface LeavesCache : NSObject

@property (assign,nonatomic) CGSize pageSize;
@property (assign) id<LeavesViewDataSource> dataSource;

- (id) initWithPageSize:(CGSize)aPageSize;
- (CGImageRef) cachedImageForPageIndex:(NSUInteger)pageIndex;
- (void) precacheImageForPageIndex:(NSUInteger)pageIndex;
- (void) minimizeToPageIndex:(NSUInteger)pageIndex viewMode:(LeavesViewMode)viewMode;
- (void) flush;

@end
