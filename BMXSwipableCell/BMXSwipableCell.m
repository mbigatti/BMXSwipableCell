//
// BMXSwipableCell.m
//
// Copyright (c) 2013-2014 Massimiliano Bigatti.
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

#import "BMXSwipableCell.h"
#import "BMXSwipableCellGestureDelegate.h"

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

@property (nonatomic, weak, readwrite) UITableView *tableView;

// Overridden properties from header file
@property (nonatomic, assign, readwrite) BOOL showingBasement;

@end


//
//
//
@implementation BMXSwipableCell {
    UITapGestureRecognizer *_tapGesture;
    UIPanGestureRecognizer *_panGesture;
    
    BMXSwipableCellGestureDelegate *_gestureDelegate;
    CGPoint _start;
    
    BOOL _userTouchedCellWhenBasementOpen;
}


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
    while (view && (! [view isKindOfClass: [UITableView class]])) {
        view = view.superview;
    }

#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    if (! view) {
        // cell is not contained in a UITableView view hierarchy
        NSLog(@"UITableView not found");
    }
#endif

    self.tableView = (UITableView*)view;
}

//
// in case of device rotation, subviews positions are corrected
//
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //
    // check if other views was added after cell creation
    // for example, this happens when populating a label
    // with standard UITableViewCell and that same label
    // is not initialized in NIB/Storyboard
    //
    [self bmx_moveContentViewSubViews];
    
    //
    // resize views
    //
    {
        CGFloat w = CGRectGetWidth(self.bounds);
        CGFloat h = CGRectGetHeight(self.bounds);
        if (self.editing) {
            w -= kDefaultUITableViewDeleteControlWidth;
        }
        
        self.scrollView.contentSize = CGSizeMake(w + self.basementVisibleWidth, h);
        self.scrollView.frame = CGRectMake(0, 0, w, h);
        self.basementView.frame = CGRectMake(w - self.basementVisibleWidth, 0, self.basementVisibleWidth, h);
        self.scrollViewContentView.frame = CGRectMake(0, 0, w, h);
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.scrollView setContentOffset: CGPointZero animated: NO];
    _scrollView.userInteractionEnabled = NO;
    [self bmx_resetAccessoryView];
}

- (void)setSelected:(BOOL)selected
{
    if (self.selected != selected) {
        [super setSelected: selected];
        [self bmx_coverAllBasementAndSetBasementHidden: YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected != selected) {
        [super setSelected: selected animated: animated];
        [self bmx_coverAllBasementAndSetBasementHidden: YES];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (self.highlighted != highlighted) {
        [super setHighlighted: highlighted];
        [self bmx_coverAllBasementAndSetBasementHidden: YES];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (self.highlighted != highlighted) {
        [super setHighlighted: highlighted animated: animated];
        [self bmx_coverAllBasementAndSetBasementHidden: YES];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing: editing animated: animated];
    
    self.scrollView.scrollEnabled = !editing;
    
    _basementView.hidden = editing;
    
    
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"setEditing: bmx_coverBasement");
#endif
    [self bmx_coverBasement];
}


#pragma mark - Privates

- (void)bmx_initialize
{
    //
    // default values
    //
    self.basementVisibleWidth = kDefaultBasementVisibleWidth;
    self.swipeEnabled = YES;
    self.hideAccessoryViewWhenBasementOpened = YES;
    
    //
    // setup scroll view
    //
    {
        _scrollView = [[UIScrollView alloc] initWithFrame: CGRectZero];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.userInteractionEnabled = NO;
    }
    
    //
    // setup basement view (for buttons or other custom content)
    //
    {
        _basementView = [[UIView alloc] initWithFrame: CGRectZero];
        _basementView.backgroundColor = [UIColor clearColor];
        
        [_scrollView addSubview: _basementView];
    }
    
    //
    // setup scroll content view
    //
    {
        _scrollViewContentView = [[UIView alloc] init];
        _scrollViewContentView.backgroundColor = self.contentView.backgroundColor;
        
        [_scrollView addSubview: _scrollViewContentView];
    }
    
    {
        // The cell is already delegate of some gesture recognizer classes and to prevent conflicts use this object.
        _gestureDelegate = [[BMXSwipableCellGestureDelegate alloc] initWithCell:self];
        
        // Is only usable if the userInteractionEnabled property of the scrollview is set to YES.
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bmx_handleSingleTap:)];
        
        // Is only usable if the userInteractionEnabled property of the scrollview is set to NO.
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(bmx_handlePanGesture:)];
        _panGesture.minimumNumberOfTouches = 1;
        _panGesture.delegate = _gestureDelegate;
        
        [_scrollView addGestureRecognizer: _tapGesture];
        [self.contentView addGestureRecognizer: _panGesture];
    }
    
    //
    // close basement when table scrolls
    //
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enclosingTableViewDidScroll:)
                                                 name: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                               object: nil];
    
    [self layoutIfNeeded];
    
    //
    // move subviews
    //
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
                    if ([constraint isMemberOfClass:NSLayoutConstraint.class]) {

					UIView *firstItem = (UIView *)constraint.firstItem;
					UIView *secondItem = (UIView *)constraint.secondItem;

					if (!firstItem || !secondItem) {
						continue;
					}

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
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
			} else {
				NSLog(@"Warning: Unsupported %@ instance in content view autolayout constraints: please set -[translatesAutoresizingMaskIntoConstraints] property to NO for the -[BMXSwipableCell contentView] subview if this constaint is not expected.",
					   NSStringFromClass(constraint.class));
#endif
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

- (void)bmx_deselectCurrentCell
{
    //
    // deselect current cell if dragging
    //
    NSIndexPath *indexPath = [self.tableView indexPathForCell: self];
    
    [self.tableView deselectRowAtIndexPath: indexPath
                                  animated: NO];
    
    if ([self.tableView.delegate respondsToSelector: @selector(tableView:didDeselectRowAtIndexPath:)]) {
        [self.tableView.delegate tableView:self.tableView
             didDeselectRowAtIndexPath: indexPath];
    }
}

- (void)bmx_coverAllBasementAndSetBasementHidden:(BOOL)hidden
{
    [self bmx_coverBasementOfAllCellsExcept: self.scrollView];
    self.basementView.hidden = hidden;
    self.showingBasement = NO;
}

- (void)bmx_basementDidAppear
{
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"bmx_basementDidAppear");
#endif
    
    if (!_showingBasement) {
        _scrollView.userInteractionEnabled = YES;
        _showingBasement = YES;
        _panGesture.enabled = NO;
        
        //
        // notify cell delegate about change in visibility of basement
        //
        if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
            [self.delegate cell: self basementVisibilityChanged: self.showingBasement];
        }
    }
}

- (void)bmx_coverBasement
{
    if (_showingBasement) {
        [self.scrollView setContentOffset: CGPointZero
                                 animated: YES];
        
        _scrollView.userInteractionEnabled = NO;
        _showingBasement = NO;
        _panGesture.enabled = YES;
        
        // hide accessory view?
        
        //
        // notify cell delegate about change in visibility of basement
        //
        if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
            [self.delegate cell: self basementVisibilityChanged: self.showingBasement];
        }
    }
}

- (void)bmx_resetAccessoryView {
    if (_hideAccessoryViewWhenBasementOpened) {
        self.accessoryView.hidden = NO;
    } else {
        self.accessoryView.transform = CGAffineTransformIdentity;
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"scrollViewWillEndDragging");
#endif
    
    //
    // Called when basement is visible and the cell dragging is
    // managed by the scroll view.
    //
	if (scrollView.contentOffset.x <= self.basementVisibleWidth) {
		*targetContentOffset = CGPointZero;
		[self bmx_coverBasement];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"scrollViewDidScroll contentOffset.x=%f", scrollView.contentOffset.x);
#endif
    
    if (self.editing) {
        return;
    }
    
    if (scrollView.contentOffset.x < 0) {
        // prevent scrolling to the right
        scrollView.contentOffset = CGPointZero;
        //[self bmx_resetAccessoryView];
        
    } else if (scrollView.contentOffset.x == 0) {
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
        NSLog(@"scrollViewDidScroll: cover basement");
#endif
        [self bmx_coverBasement];
        [self bmx_resetAccessoryView];
        
	} else {
        // slide view
        self.basementView.hidden = NO;
        self.basementView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - self.basementVisibleWidth),
                                             0.0f,
                                             self.basementVisibleWidth,
                                             CGRectGetHeight(self.bounds));
        
        if (_hideAccessoryViewWhenBasementOpened) {
            self.accessoryView.hidden = YES;
        } else {
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
            NSLog(@"scrollViewDidScroll: translating accessory view by %f", scrollView.contentOffset.x);
#endif
            self.accessoryView.transform = CGAffineTransformMakeTranslation(-scrollView.contentOffset.x, 0);
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewDidEndDecelerating: content offset %f", scrollView.contentOffset.x);
    if (scrollView.contentOffset.x == 0) {
        [self bmx_resetAccessoryView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"scrollViewDidEndScrollingAnimation: %f", _scrollView.contentOffset.x);
#endif
    if ( _scrollView.contentOffset.x == _basementVisibleWidth ) {
        [self bmx_basementDidAppear];
        
    } else { //if ( _scrollView.contentOffset.x == 0.0f ) {
        _basementView.hidden = YES;
        [self bmx_resetAccessoryView];
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
    [self bmx_coverBasement];
}


#pragma mark - Gesture Methods

- (void)bmx_handleSingleTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:_scrollView];
    if ( CGRectContainsPoint(_scrollViewContentView.frame, point) ) {
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
        NSLog(@"bmx_handleSingleTap: bmx_coverBasement");
#endif
        [self bmx_coverBasement];
    }
}

- (void)bmx_handlePanGesture:(UIPanGestureRecognizer *)gesture {
#ifdef BMX_SWIPABLE_CELL_LOG_ENABLED
    NSLog(@"%@", [gesture description]);
#endif
    
    if ( self.isEditing || _showingBasement || !_swipeEnabled) {
        return;
    }
    
    if (self.selected) {
        [self bmx_deselectCurrentCell];
    }
    
    CGPoint position = [gesture locationInView:self];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _start = position;
            [self bmx_coverAllBasementAndSetBasementHidden: YES];
        } break;
            
        case UIGestureRecognizerStateChanged: {
            [_scrollView setContentOffset: CGPointMake(MAX((_start.x - position.x), 0.0f), 0.0f)];
        } break;
            
        case UIGestureRecognizerStateEnded: {
            if ( _scrollView.contentOffset.x >= ceilf(_basementVisibleWidth / 2.0f) ) {
                [_scrollView setContentOffset: CGPointMake(_basementVisibleWidth, 0.0f)
                                     animated: YES];
                
            } else {
                [_scrollView setContentOffset: CGPointZero
                                     animated:YES];
                
                //[self bmx_resetAccessoryView];
            }
        } break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [_scrollView setContentOffset: CGPointZero animated: YES];
            _scrollView.userInteractionEnabled = NO;
            //[self bmx_resetAccessoryView];
        } break;
            
        default:
            break;
    }
}


#pragma mark - Show and hide basement

- (void)showBasement:(BOOL)animated
{
    [self.scrollView setContentOffset:CGPointMake(self.basementVisibleWidth, 0.f) animated:YES];
    _scrollView.userInteractionEnabled = YES;
    _showingBasement = YES;
    _panGesture.enabled = NO;
}

- (void)hideBasement:(BOOL)animated
{
    [self bmx_coverBasement];
}


#pragma mark - Class methods

+ (void)hideBasementOfAllCells
{
    [[NSNotificationCenter defaultCenter] postNotificationName: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                        object: nil];
}

@end


#undef BMX_SWIPABLE_CELL_LOG_ENABLED
