#import <UIKit/UIKit.h>

#import "LeavesView.h"
@interface ViewController : UIViewController<LeavesViewDataSource, LeavesViewDelegate> {
    LeavesView *leavesView;
}

@end

