#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
typedef enum {
    LeavesViewModeSinglePage,
    LeavesViewModeFacingPages,
} LeavesViewMode;
@class LeavesCache;

@protocol LeavesViewDataSource;
@protocol LeavesViewDelegate;

@interface LeavesView : UIView 

@property (nonatomic, weak) id<LeavesViewDataSource> dataSource;
@property (nonatomic, weak) id<LeavesViewDelegate> delegate;
@property (nonatomic, assign) LeavesViewMode mode;
@property (readonly) CGFloat targetWidth;
@property (nonatomic, assign) NSUInteger currentPageIndex;
@property (assign) BOOL backgroundRendering;

- (void) reloadData;

@end

@protocol LeavesViewDataSource <NSObject>

- (NSUInteger) numberOfPagesInLeavesView:(LeavesView*)leavesView;
- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx;

@end

@protocol LeavesViewDelegate <NSObject>

@optional

- (void) leavesView:(LeavesView *)leavesView willTurnToPageAtIndex:(NSUInteger)pageIndex;
- (void) leavesView:(LeavesView *)leavesView didTurnToPageAtIndex:(NSUInteger)pageIndex;

@end

