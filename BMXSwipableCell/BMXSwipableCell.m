//
// BMXSwipableCell.m
//
// Copyright (c) 2013 Massimiliano Bigatti.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "BMXScrollView.h"
#import "BMXSwipableCell.h"

#define BMX_SWIPABLE_CELL_LOG_ENABLED
#undef BMX_SWIPABLE_CELL_LOG_ENABLED

//
// public constants
//
NSString *const BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification = @"BMXSwipableCellEnclosingTableViewDidScrollNotification";
NSString *const BMXSwipableCellScrollViewKey = @"BMXSwipableCellScrollViewKey";


// private constants
static const CGFloat kDefaultBasementVisibleWidth = 120;
static const CGFloat kDefaultUITableViewDeleteControlWidth = 47;

//
//
//
@interface BMXSwipableCell ()

// Overridden properties from header file

@end


@implementation BMXSwipableCell


#pragma mark - Lifecycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self bmx_initialize];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self bmx_initialize];
    }
    return self;
}

- (void)dealloc
{   
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                  object: nil];
}


#pragma mark - Properties

- (void)setBasementVisibleWidth:(CGFloat)catchWidth
{
    _basementVisibleWidth = catchWidth;
    [self setNeedsLayout];
}


#pragma mark - UITableViewCell Overrides

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    //
    // search for the parent table view
    //
    UIView *view = self.superview;
    while (! [view isKindOfClass: [UITableView class]]) {
        view = view.superview;
    }
    
    NSAssert([view isKindOfClass: [UITableView class]], @"UITableView not found");
}

//
// in case of device rotation, subviews positions are corrected
//
- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    //
//    // check if other views was added after cell creation
//    // for example, this happens when populating a label
//    // with standard UITableViewCell and that same label
//    // is not initialized in NIB/Storyboard
//    //
//    [self bmx_moveContentViewSubViews];

    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    if (self.editing)
    {
        w -= kDefaultUITableViewDeleteControlWidth;
    }

    self.scrollView.contentSize = CGSizeMake(w + self.basementVisibleWidth, h);
    self.scrollView.frame = CGRectMake(0, 0, w, h);
    self.basementView.frame = CGRectMake(w - self.basementVisibleWidth, 0, self.basementVisibleWidth, h);
    self.scrollViewContentView.frame = CGRectMake(0, 0, w, h);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.scrollView setContentOffset:CGPointZero animated:NO];
    self.accessoryView.transform = CGAffineTransformIdentity;
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.isShowingBasement)
    {
        [self coverBasementForced:NO animated:YES];
    }
    else if (self.selected != selected)
    {
        [super setSelected: selected animated: animated];
        self.basementView.hidden = (selected || self.highlighted ? YES : NO);
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (self.isShowingBasement)
    {
        [self coverBasementForced:NO animated:YES];
    }
    else if (self.highlighted != highlighted && !self.isShowingBasement)
    {
        [super setHighlighted:highlighted animated:animated];
        self.basementView.hidden = (highlighted || self.selected ? YES : NO);
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing: editing animated: animated];
    self.scrollView.scrollEnabled = !editing;
    [self coverBasementForced:YES animated:animated];
}


#pragma mark - Privates

- (void)bmx_initialize
{
    self.basementVisibleWidth = kDefaultBasementVisibleWidth;

    _scrollView = [[BMXScrollView alloc] initWithFrame: CGRectZero];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.delaysContentTouches = NO;

    _basementView = [[UIView alloc] initWithFrame: CGRectZero];
    _basementView.backgroundColor = [self.contentView backgroundColor];
    _basementView.clipsToBounds = YES;
    [_scrollView addSubview: _basementView];
    _scrollView.panGestureRecognizer.delaysTouchesBegan = YES;

    _scrollViewContentView = [[UIView alloc] init];
    _scrollViewContentView.backgroundColor = self.contentView.backgroundColor;
    _scrollViewContentView.clipsToBounds = YES;
    [_scrollView addSubview: _scrollViewContentView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enclosingTableViewDidScroll:)
                                                 name:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                               object:nil];
    
    [self layoutIfNeeded];

    [self bmx_moveContentViewSubViews];
}

- (void)bmx_moveContentViewSubViews
{
    //
    // move storyboard / custom cell subviews into the scroll view
    //
    NSArray *constraints = [self.contentView constraints];
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"constraints.count=%d", constraints.count);
#endif
    
    NSMutableArray *newConstraints = [@[] mutableCopy];
    
    for (UIView *view in self.contentView.subviews) {
        if (view != self.scrollView) {
            
            for (NSLayoutConstraint *constraint in constraints) {
                
                UIView *firstItem = (UIView *)constraint.firstItem;
                UIView *secondItem = (UIView *)constraint.secondItem;
                
                if (firstItem == self.contentView) {
                    firstItem = self.scrollViewContentView;
                }
                
                if (secondItem == self.contentView) {
                    secondItem = self.scrollViewContentView;
                }
                
                // create new constraint
                NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem: firstItem
                                                                                 attribute: constraint.firstAttribute
                                                                                 relatedBy: constraint.relation
                                                                                    toItem: secondItem
                                                                                 attribute: constraint.secondAttribute
                                                                                multiplier: constraint.multiplier
                                                                                  constant: constraint.constant];
                newConstraint.priority = constraint.priority;
                [newConstraints addObject: newConstraint];
            }
            
            [view removeFromSuperview];
            [self.scrollViewContentView addSubview: view];
        }
    }
    
    if (newConstraints.count > 0) {
        [self.scrollViewContentView addConstraints:newConstraints];
    }
    
    [self.contentView addSubview: self.scrollView];
}


/**
 Closes the basement of all cells
 */
- (void)bmx_coverBasementOfAllCellsExcept:(UIScrollView*)scrollView
{
    if (scrollView != nil) {
        //
        // close cells basement if user start swiping on a cell
        // object parameter is the view to be ignored
        //
        [[NSNotificationCenter defaultCenter] postNotificationName: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                            object: nil
                                                          userInfo: @{ BMXSwipableCellScrollViewKey: scrollView} ];
    }
}

- (void)coverBasementForced:(BOOL)force animated:(BOOL)animated
{
    if (self.isShowingBasement &&
        ((!self.scrollView.isDragging && !self.scrollView.isDecelerating) || force))
    {
        [self.scrollView setContentOffset: CGPointZero
                                 animated: animated];
        self.accessoryView.transform = CGAffineTransformIdentity;
        if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
            [self.delegate cell: self basementVisibilityChanged: self.showingBasement];
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"scrollViewWillEndDragging");
#endif

	if (scrollView.contentOffset.x <= self.basementVisibleWidth) {
		*targetContentOffset = CGPointZero;
        self.accessoryView.transform = CGAffineTransformIdentity;
	}
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    [self setSelected:NO animated:NO];
//    [self setHighlighted:NO animated:NO];
//}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self bmx_coverBasementOfAllCellsExcept:self.scrollView];
    [self setSelected:NO animated:NO];
    [self setHighlighted:NO animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"scrollViewDidScroll contentOffset.x=%f", scrollView.contentOffset.x);
#endif

    if (self.scrollView.contentOffset.x <= 0.f && !self.isEditing)
    {
        scrollView.contentOffset = CGPointZero;
        self.accessoryView.transform = CGAffineTransformIdentity;
    }
    else
    {
        // slide view
        self.basementView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - self.basementVisibleWidth),
                                             0.0f,
                                             self.basementVisibleWidth,
                                             CGRectGetHeight(self.bounds));
//
        self.accessoryView.transform = CGAffineTransformMakeTranslation(-scrollView.contentOffset.x, 0);
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ( _scrollView.contentOffset.x == _basementVisibleWidth )
    {
        if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
            [self.delegate cell: self basementVisibilityChanged:self.showingBasement];
        }
    }
}


#pragma mark - Notifications

- (void)enclosingTableViewDidScroll:(NSNotification*)notification
{
    //
    // ignore reset on scroll view passed as parameter
    //
    NSObject *scrollView = [notification.userInfo objectForKey: BMXSwipableCellScrollViewKey];
    
    if (scrollView == self.scrollView) {
        return;
    }
    
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"enclosingTableViewDidScroll: bmx_coverBasement");
#endif
    [self coverBasementForced:YES animated:YES];
}


#pragma mark - Gesture Methods

- (void)openBasement:(BOOL)animated
{
    [self.scrollView setContentOffset:CGPointMake(self.basementVisibleWidth, 0.f) animated:animated];
}

- (void)closeBasement:(BOOL)animated
{
    [self coverBasementForced:YES animated:animated];
}

- (BOOL)isShowingBasement
{
    return (self.scrollView.contentOffset.x > 0.f);
}

#pragma mark - Class methods

+ (void)coverBasementOfAllCells
{
    [[NSNotificationCenter defaultCenter] postNotificationName: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                        object: nil];
}

@end

