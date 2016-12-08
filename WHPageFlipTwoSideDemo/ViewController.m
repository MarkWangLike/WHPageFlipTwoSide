#import "ViewController.h"
#import "Utilities.h"
@interface ViewController ()
@property(nonatomic, strong)NSArray *images;
@end

@implementation ViewController

#pragma mark  UIViewController methods
- (void)loadView {
    [super loadView];
    leavesView.frame = CGRectMake(0, 0,100, 100);
    leavesView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:leavesView];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    leavesView.frame = self.view.bounds;
    [self images];
    leavesView.dataSource = self;
    leavesView.delegate = self;
    [leavesView reloadData];
}
- (id)init {
    if (self = [super init]) {
        leavesView = [[LeavesView alloc] initWithFrame:CGRectZero];
        leavesView.mode = LeavesViewModeSinglePage;
    }
    return self;
}

#pragma mark LeavesViewDataSource methods
- (NSUInteger) numberOfPagesInLeavesView:(LeavesView*)leavesView {
    return _images.count;
}

- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx {
    if (!(index < _images.count)) {
        return;
    }
    UIImage *image = [_images objectAtIndex:index];
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGAffineTransform transform = aspectFit(imageRect,
                                            CGContextGetClipBoundingBox(ctx));
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, imageRect, [image CGImage]);
    
}

- (NSArray *)images{
    if (_images == nil) {
        _images = [[NSArray alloc] initWithObjects:
                   [UIImage imageNamed:@"cat1.jpg"],
                   [UIImage imageNamed:@"cat2.jpg"],
                   [UIImage imageNamed:@"cat3.jpg"],
                   [UIImage imageNamed:@"cat4.jpg"],
                   nil];
    }
    return _images;
}
#pragma mark Interface rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        leavesView.mode = LeavesViewModeSinglePage;
    } else {
        leavesView.mode = LeavesViewModeFacingPages;
    }
}

@end
