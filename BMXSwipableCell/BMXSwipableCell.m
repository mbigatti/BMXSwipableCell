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

@interface BMXSwipableCell ()

@property (nonatomic, strong) UITableView *table;

// Overridden properties from header file
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
    [[NSNotificationCenter defaultCenter] removeObserver: self name:BMXSwipableCellEnclosingTableViewDidBeginScrollingNotification object: nil];
}


#pragma mark - Privates

- (void)initialize {
    self.catchWidth = DEFAULT_CATCH_WIDTH;
    
    //
    // setup scroll view
    //
    {
        CGRect rect = CGRectMake(0,
                                 0,
                                 CGRectGetWidth(self.bounds),
                                 CGRectGetHeight(self.bounds));
        
        self.scrollView = [[UIScrollView alloc] initWithFrame: rect];
        
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + self.catchWidth,
                                                 CGRectGetHeight(self.bounds));
        self.scrollView.delegate = self;
        self.scrollView.showsHorizontalScrollIndicator = NO;
    }
    
    //
    // setup basement view (for buttons)
    //
    {
        CGRect rect = CGRectMake(CGRectGetWidth(self.bounds) - self.catchWidth,
                                 0,
                                 self.catchWidth,
                                 CGRectGetHeight(self.bounds));
        
        self.basementView = [[UIView alloc] initWithFrame: rect];
        self.basementView.backgroundColor = [UIColor clearColor];
        
        [self.scrollView addSubview: self.basementView];
    }
    
    //
    // setup scroll content view
    //
    {
        CGRect rect = CGRectMake(0,
                                 0,
                                 CGRectGetWidth(self.bounds),
                                 CGRectGetHeight(self.bounds));
        
        self.scrollViewContentView = [[BMXSwipableCellContentView alloc] initWithFrame: rect cell: self];
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
        // close menu cells if user start swiping on a cell
        // object parameter is the exception
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


#pragma mark - Overrides

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
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + self.catchWidth, CGRectGetHeight(self.bounds));
    
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected: selected animated: animated];
    
    [self hideBasementOfAllCellsExcept: self.scrollView];
    self.basementView.hidden = selected;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing: editing animated: animated];
    
    self.scrollView.scrollEnabled = !self.editing;
    
    if (self.showingBasement) {
        //
        // hide basement
        //
        [self.scrollView setContentOffset: CGPointZero
                                 animated: YES];
    }
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
	if (scrollView.contentOffset.x > self.catchWidth) {
		targetContentOffset->x = self.catchWidth;
        
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
	
	if (scrollView.contentOffset.x >= self.catchWidth) {
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


#pragma mark - Publics

- (void)cellTapped
{
    //
    // if touch began and cell is showing menu, does not
    // trigger cell selection
    //
    if (self.showingBasement) {
        return;
    }
    
    //
    // select row tapped
    //
    NSIndexPath *indexPath = [self.table indexPathForCell: self];
    
  [self.table selectRowAtIndexPath: indexPath
                          animated: NO
                    scrollPosition: UITableViewScrollPositionNone];
  
    if ([self.table.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [self.table.delegate tableView: self.table
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

#undef DEFAULT_CATCH_WIDTH
