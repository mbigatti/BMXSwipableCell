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

#define DEFAULT_CATCH_WIDTH 120

NSString *const BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification = @"BMXSwipableCellEnclosingTableViewDidScrollNotification";
NSString *const BMXSwipableCellScrollViewKey = @"BMXSwipableCellScrollViewKey";


@interface BMXSwipableCell ()

@property (nonatomic, strong) UITableView *table;

// Overridden properties from header file
@property (nonatomic, assign, readwrite) BOOL showingBasement;
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;
@property (nonatomic, strong, readwrite) BMXSwipableCellContentView *scrollViewContentView;
@property (nonatomic, strong, readwrite) UIView *basementView;

@end


@implementation BMXSwipableCell


#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                  object: nil];
}


#pragma mark - Properties

- (void)setCatchWidth:(CGFloat)catchWidth
{
    _catchWidth = catchWidth;
    [self setNeedsLayout];
}


#pragma mark - UITableViewCell Overrides

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    //
    // search for the parent table view
    //
    UIView *view = self.superview;
    while (! [view isKindOfClass: [UITableView class]]) {
        view = view.superview;
    }
    
    NSAssert([view isKindOfClass: [UITableView class]], @"UITableView not found");
    
    self.table = (UITableView*)view;
}

//
// in case of device rotation, subviews positions are corrected
//
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + self.catchWidth,
                                             CGRectGetHeight(self.bounds));
    
    self.scrollView.frame = CGRectMake(0,
                                       0,
                                       CGRectGetWidth(self.bounds),
                                       CGRectGetHeight(self.bounds));
    
    self.basementView.frame = CGRectMake(CGRectGetWidth(self.bounds) - self.catchWidth,
                                         0,
                                         self.catchWidth,
                                         CGRectGetHeight(self.bounds));
    
    self.scrollViewContentView.frame = CGRectMake(0,
                                                  0,
                                                  CGRectGetWidth(self.bounds),
                                                  CGRectGetHeight(self.bounds));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.scrollView setContentOffset: CGPointZero
                             animated: NO];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected: selected];
    
    [self hideBasementOfAllCellsExcept: self.scrollView];
    self.basementView.hidden = selected;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected: selected animated: animated];
    
    [self hideBasementOfAllCellsExcept: self.scrollView];
    self.basementView.hidden = selected;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted: highlighted];
    
    [self hideBasementOfAllCellsExcept: self.scrollView];
    self.basementView.hidden = highlighted;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted: highlighted animated: animated];
    
    [self hideBasementOfAllCellsExcept: self.scrollView];
    self.basementView.hidden = highlighted;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing: editing animated: animated];
    
    self.scrollView.scrollEnabled = !editing;
    self.basementView.hidden = editing;
    
    if (self.showingBasement) {
        //
        // hide basement if currently shown
        //
        [self.scrollView setContentOffset: CGPointZero
                                 animated: YES];
    }
}


#pragma mark - Privates

- (void)initialize {
    self.catchWidth = DEFAULT_CATCH_WIDTH;
    
    //
    // setup scroll view
    //
    {
        self.scrollView = [[UIScrollView alloc] initWithFrame: CGRectZero];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.delegate = self;
    }
    
    //
    // setup basement view (for buttons)
    //
    {
        self.basementView = [[UIView alloc] initWithFrame: CGRectZero];
        self.basementView.backgroundColor = [UIColor clearColor];
        
        [self.scrollView addSubview: self.basementView];
    }
    
    //
    // setup scroll content view
    //
    {
        self.scrollViewContentView = [[BMXSwipableCellContentView alloc] initWithFrame: CGRectZero cell: self];
        self.scrollViewContentView.backgroundColor = self.contentView.backgroundColor;
        
        [self.scrollView addSubview: self.scrollViewContentView];
    }
    
    //
    // move storyboard cell subviews into the scroll view
    //
    NSArray *subviews = self.contentView.subviews;
    for (UIView *view in subviews) {
        [view removeFromSuperview];
        [self.scrollViewContentView addSubview: view];
    }
    
    [self.contentView addSubview: self.scrollView];
    
    //
    // hide basement when table scrolls
    //
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enclosingTableViewDidScroll:)
                                                 name: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                               object: nil];
}

- (void)hideBasementOfAllCellsExcept:(UIScrollView*)scrollView {
    if (scrollView != nil) {
        //
        // close menu cells if user start swiping on a cell
        // object parameter is the exception
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                            object: nil
                                                          userInfo: @{ BMXSwipableCellScrollViewKey: scrollView}];
    }
}

- (void)dispatchDidDeselectMessageForIndexPath:(NSIndexPath*)indexPath {
    if ([self.table.delegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
        [self.table.delegate tableView: self.table
             didDeselectRowAtIndexPath: indexPath];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
	if (scrollView.contentOffset.x > self.catchWidth) {
		targetContentOffset->x = self.catchWidth;
        
        //
        // moved logic here so the event fires when user finish
        // dragging and not when the basement is fully visible
        //
		if (!self.showingBasement) {
			self.showingBasement = YES;

            if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
                
                [self.delegate cell: self
          basementVisibilityChanged: self.showingBasement];
            }
        }
        
	} else {
		*targetContentOffset = CGPointZero;
		
		// Need to call this subsequently to remove flickering. Strange.
		dispatch_async(dispatch_get_main_queue(), ^{
			[scrollView setContentOffset: CGPointZero
                          animated: YES];
		});
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideBasementOfAllCellsExcept: scrollView];
    
    //
    // if user starts dragging a cell, deselect other cells in the table
    //
    NSArray *selectedCells = [self.table indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in selectedCells) {
        [self.table deselectRowAtIndexPath: indexPath animated: NO];
        [self dispatchDidDeselectMessageForIndexPath: indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.contentOffset.x < 0.0f) {
		scrollView.contentOffset = CGPointZero;
	}
	
	self.basementView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - self.catchWidth), 0.0f, self.catchWidth, CGRectGetHeight(self.bounds));

//
// removed -> see scrollViewWillEndDragging:withVelocity:targetContentOffset
//
//	if (scrollView.contentOffset.x >= self.catchWidth) {
//		if (!self.showingBasement) {
//			self.showingBasement = YES;
//          // notify delegate
//		}
//	} else
    if (scrollView.contentOffset.x == 0.0f) {
		if (self.showingBasement) {
			self.showingBasement = NO;
            
            //
            // notify cell delegate about change in visibility of basement
            //
            if ([self.delegate respondsToSelector:@selector(cell:basementVisibilityChanged:)]) {
                
                [self.delegate cell: self
          basementVisibilityChanged: self.showingBasement];
            }
        }
	}

    //
    // deselect current cell if dragging
    //
    NSIndexPath *indexPath = [self.table indexPathForCell: self];
    [self.table deselectRowAtIndexPath: indexPath
                              animated: NO];
    [self dispatchDidDeselectMessageForIndexPath: indexPath];
}


#pragma mark - Notifications

- (void)enclosingTableViewDidScroll:(NSNotification*)notification {
    //
    // ignore reset on scroll view passed as parameter
    //
    NSObject *scrollView = [notification.userInfo objectForKey: BMXSwipableCellScrollViewKey];
    
    if (scrollView == self.scrollView) {
        return;
    }
    
    [self.scrollView setContentOffset: CGPointZero
                             animated: YES];
}


#pragma mark - Content view callbacks

- (void)cellTouchedDown {
    //
    // if touch began and cell is showing menu, does not
    // trigger cell selection
    //
    if (self.showingBasement) {
        return;
    }
    
    NSIndexPath *indexPath = [self.table indexPathForCell: self];
    id<UITableViewDelegate> delegate = self.table.delegate;
    
    //
    // if delegate agrees, highlight the cell
    //
    BOOL shouldHighlight = YES;
    if ([delegate respondsToSelector: @selector(tableView:shouldHighlightRowAtIndexPath:)]) {
        shouldHighlight = [delegate tableView: self.table
                     shouldHighlightRowAtIndexPath: indexPath];
    }
    
    if (shouldHighlight) {
        self.highlighted = YES;
        
        if ([delegate respondsToSelector: @selector(tableView:didHighlightRowAtIndexPath:)]) {
            
            [delegate tableView: self.table didHighlightRowAtIndexPath: indexPath];
        }
    }    
}

- (void)cellTouchedUp {
    if (self.highlighted) {
        self.highlighted = NO;
        
        //
        // select row tapped
        //
        NSIndexPath *indexPath = [self.table indexPathForCell: self];
        
        [self.table selectRowAtIndexPath: indexPath
                                animated: NO
                          scrollPosition: UITableViewScrollPositionNone];
        
        id<UITableViewDelegate> delegate = self.table.delegate;
        
        if ([delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            [delegate tableView: self.table didSelectRowAtIndexPath: indexPath];
        }
    }
}

- (void)cellTouchCancelled
{
    self.highlighted = NO;
}


#pragma mark - Class methods

+ (void)hideBasementOfAllCells
{
    [[NSNotificationCenter defaultCenter] postNotificationName: BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                        object: nil];
}

@end

#undef DEFAULT_CATCH_WIDTH
