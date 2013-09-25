//
//  BMXSwipableCell.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXSwipableCell.h"

#define DEFAULT_CATCH_WIDTH 120

NSString *const BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification = @"BMXSwipableCellEnclosingTableViewDidScrollNotification";
NSString *const BMXSwipableCellScrollViewKey = @"BMXSwipableCellScrollViewKey";


@implementation BMXSwipableCell {
    UITableView *_table;
}


#pragma mark - Lifecycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setup];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Privates

- (void)setup
{
    _catchWidth = DEFAULT_CATCH_WIDTH;
    
    //
    // setup scroll view
    //
    {
        CGRect rect = CGRectMake(0,
                                 0,
                                 CGRectGetWidth(self.bounds),
                                 CGRectGetHeight(self.bounds));
        
        _scrollView = [[UIScrollView alloc] initWithFrame: rect];
        
        _scrollView.contentSize = CGSizeMake(
                                            CGRectGetWidth(self.bounds) + _catchWidth,
                                            CGRectGetHeight(self.bounds));
        _scrollView.delegate = self;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    
    //
    // setup basement view (for buttons)
    //
    {
        CGRect rect = CGRectMake(CGRectGetWidth(self.bounds) - _catchWidth,
                                 0,
                                 _catchWidth,
                                 CGRectGetHeight(self.bounds));
        
        _basementView = [[UIView alloc] initWithFrame: rect];
        _basementView.backgroundColor = [UIColor clearColor];
        
        [_scrollView addSubview: _basementView];
    }
    
    //
    // setup scroll content view
    //
    {
        CGRect rect = CGRectMake(0,
                                 0,
                                 CGRectGetWidth(self.bounds),
                                 CGRectGetHeight(self.bounds));
        
        _scrollViewContentView = [[BMXSwipableCellContentView alloc] initWithFrame: rect cell: self];
        _scrollViewContentView.backgroundColor = self.contentView.backgroundColor;
        
        [_scrollView addSubview: _scrollViewContentView];
    }
    
    //
    // move storyboard cell subviews into the scroll view
    //
    NSArray *subviews = self.contentView.subviews;
    for (UIView *view in subviews) {
        [view removeFromSuperview];
        [_scrollViewContentView addSubview: view];
    }
    
    [self.contentView addSubview: _scrollView];
    
    //
    // hide basement when table scrolls
    //
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enclosingTableViewDidScroll:) name:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                               object: nil];

}

- (void)hideBasementOfAllCellsExcept:(UIScrollView*)scrollView
{
    // close menu cells if user start swiping on a cell
    // object parameter is the exception
    [[NSNotificationCenter defaultCenter] postNotificationName:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                        object: nil
                                                      userInfo: @{ BMXSwipableCellScrollViewKey: scrollView}];
}

- (void)dispatchDidDeselectMessageForIndexPath:(NSIndexPath*)indexPath
{
    if ([_table.delegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
        [_table.delegate tableView: _table
         didDeselectRowAtIndexPath: indexPath];
    }
}


#pragma mark - Overrides

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
    
    _table = (UITableView*)view;
}

//
// in case of device rotation, subviews positions are corrected
//
- (void)layoutSubviews {
    [super layoutSubviews];
    
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + _catchWidth, CGRectGetHeight(self.bounds));
    
    _scrollView.frame = CGRectMake(0,
                                   0,
                                   CGRectGetWidth(self.bounds),
                                   CGRectGetHeight(self.bounds));
    
    _basementView.frame = CGRectMake(CGRectGetWidth(self.bounds) - _catchWidth,
                                     0,
                                     _catchWidth,
                                     CGRectGetHeight(self.bounds));
    
    _scrollViewContentView.frame = CGRectMake(0,
                                              0,
                                              CGRectGetWidth(self.bounds),
                                              CGRectGetHeight(self.bounds));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [_scrollView setContentOffset: CGPointZero
                         animated: NO];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected: selected];
    
    [self hideBasementOfAllCellsExcept: _scrollView];
    _basementView.hidden = selected;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected: selected animated: animated];
    
    [self hideBasementOfAllCellsExcept: _scrollView];
    _basementView.hidden = selected;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing: editing animated: animated];
    
    self.scrollView.scrollEnabled = !self.editing;
    
    if (_showingBasement) {
        //
        // hide basement
        //
        [_scrollView setContentOffset: CGPointZero
                             animated: YES];
    }
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
	if (scrollView.contentOffset.x > _catchWidth) {
		targetContentOffset->x = _catchWidth;
        
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
    NSArray *selectedCells = [_table indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in selectedCells) {
        [_table deselectRowAtIndexPath: indexPath animated: NO];
        [self dispatchDidDeselectMessageForIndexPath: indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.contentOffset.x < 0.0f) {
		scrollView.contentOffset = CGPointZero;
	}
	
	_basementView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - _catchWidth), 0.0f, _catchWidth, CGRectGetHeight(self.bounds));
	
	if (scrollView.contentOffset.x >= _catchWidth) {
		if (!self.showingBasement) {
			self.showingBasement = YES;
			//[self.delegate cell:self didShowMenu:self.isShowingMenu];
		}
	} else if (scrollView.contentOffset.x == 0.0f) {
		if (self.showingBasement) {
			self.showingBasement = NO;
			//[self.delegate cell:self didShowMenu:self.isShowingMenu];
		}
	}
    
    //
    // deselect current cell if dragging
    //
    NSIndexPath *indexPath = [_table indexPathForCell: self];
    [_table deselectRowAtIndexPath: indexPath
                          animated: NO];
    [self dispatchDidDeselectMessageForIndexPath: indexPath];
}


#pragma mark - Notifications

- (void)enclosingTableViewDidScroll:(NSNotification*)notification {
    //
    // ignore reset on scroll view passed as parameter
    //
    NSObject *sv = [notification.userInfo objectForKey: BMXSwipableCellScrollViewKey];
    
    if (sv == _scrollView) {
        return;
    }
    
    [_scrollView setContentOffset: CGPointZero
                         animated: YES];
}


#pragma mark - Publics

- (void)cellTapped
{
    //
    // if touch began and cell is showing menu, does not
    // trigger cell selection
    //
    if (_showingBasement) {
        return;
    }
    
    //
    // select row tapped
    //
    NSIndexPath *indexPath = [_table indexPathForCell: self];
    
    [_table selectRowAtIndexPath: indexPath
                        animated: NO
                  scrollPosition: UITableViewScrollPositionNone];
    
    if ([_table.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_table.delegate tableView: _table
           didSelectRowAtIndexPath: indexPath];
    }
}


#pragma mark - Class methods

+ (void)hideBasementOfAllCells
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification
                                                        object: nil];
}

@end
