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

#import "BMXSwipableCell.h"
#import "BMXSwipableCellGestureDelegate.h"

//
// public constants
//
NSString *const BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification = @"BMXSwipableCellEnclosingTableViewDidScrollNotification";
NSString *const BMXSwipableCellScrollViewKey = @"BMXSwipableCellScrollViewKey";


// private constants
static const NSTimeInterval kDefaultBasementVisibleWidth = 120;
static const NSTimeInterval kDefaultUITableViewDeleteControlWidth = 47;

//
//
//
@interface BMXSwipableCell ()

@property (nonatomic, strong, readwrite) UITableView *tableView;

// Overridden properties from header file
@property (nonatomic, assign, readwrite) BOOL showingBasement;

@end


//
//
//
@implementation BMXSwipableCell {
    UITableView *_tableView;
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
    while (! [view isKindOfClass: [UITableView class]]) {
        view = view.superview;
    }
    
    NSAssert([view isKindOfClass: [UITableView class]], @"UITableView not found");
    
    _tableView = (UITableView*)view;
}

//
// in case of device rotation, subviews positions are corrected
//
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //
    // move storyboard / custom cell subviews into the scroll view
    //
    {
        NSArray *subviews = self.contentView.subviews;
        for (UIView *view in subviews) {
            if (view != self.scrollView) {
                [view removeFromSuperview];
                [self.scrollViewContentView addSubview: view];
            }
        }
        [self.contentView addSubview: self.scrollView];
    }
    
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

//    NSLog(@"setEditing: bmx_coverBasement");
    [self bmx_coverBasement];
}


#pragma mark - Privates

- (void)bmx_initialize
{
    self.basementVisibleWidth = kDefaultBasementVisibleWidth;
    
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
    
    if ([_tableView.delegate respondsToSelector: @selector(tableView:didDeselectRowAtIndexPath:)]) {
        [_tableView.delegate tableView: _tableView
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
//    NSLog(@"bmx_basementDidAppear");
    
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
        self.accessoryView.transform = CGAffineTransformIdentity;
        
        //
        // notify cell delegate about change in visibility of basement
        //
        if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
            [self.delegate cell: self basementVisibilityChanged: self.showingBasement];
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
//    NSLog(@"scrollViewWillEndDragging");

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
//    NSLog(@"scrollViewDidScroll contentOffset.x=%f", scrollView.contentOffset.x);

    if (self.editing) {
        return;
    }
    
    if (scrollView.contentOffset.x < 0) {
        // prevent scrolling to the right
        scrollView.contentOffset = CGPointZero;
        self.accessoryView.transform = CGAffineTransformIdentity;
        
    } else if (scrollView.contentOffset.x == 0) {
//        NSLog(@"scrollViewDidScroll: cover basement");
        [self bmx_coverBasement];
        
	} else {
        // slide view
        self.basementView.hidden = NO;
        self.basementView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - self.basementVisibleWidth),
                                             0.0f,
                                             self.basementVisibleWidth,
                                             CGRectGetHeight(self.bounds));
     
        self.accessoryView.transform = CGAffineTransformMakeTranslation(-scrollView.contentOffset.x, 0);
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ( _scrollView.contentOffset.x == _basementVisibleWidth ) {
        [self bmx_basementDidAppear];
        
    } else if ( _scrollView.contentOffset.x == 0.0f ) {
        if ( _scrollView.contentOffset.x == 0.0f ) {
            _basementView.hidden = YES;
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
    
//    NSLog(@"enclosingTableViewDidScroll: bmx_coverBasement");
    [self bmx_coverBasement];
}


#pragma mark - Gesture Methods

- (void)bmx_handleSingleTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:_scrollView];
    if ( CGRectContainsPoint(_scrollViewContentView.frame, point) ) {
//        NSLog(@"bmx_handleSingleTap: bmx_coverBasement");
        [self bmx_coverBasement];
    }
}

- (void)bmx_handlePanGesture:(UIPanGestureRecognizer *)gesture {
//    NSLog(@"%@", [gesture description]);
    
    if ( self.isEditing || _showingBasement) {
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
            }
        } break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [_scrollView setContentOffset:CGPointZero animated:YES];
            _scrollView.userInteractionEnabled = NO;
        } break;
            
        default:
            break;
    }
}


#pragma mark - Class methods

+ (void)coverBasementOfAllCells
{
    [[NSNotificationCenter defaultCenter] postNotificationName: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                        object: nil];
}

@end

