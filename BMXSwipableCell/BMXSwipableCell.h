//
// BMXSwipableCell.h
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

#import <UIKit/UIKit.h>

@class BMXSwipableCell;


/**
 The delegate of a `BMXSwipableCell` object can adopt the `BMXSwipableCellDelegate` protocol.
 */
@protocol BMXSwipableCellDelegate <NSObject>

/**
 Tells the delegate that the specified cell’s menu is now shown or hidden.
 
 @param cell    The cell whose basement was shown or hidden.
 @param showing `YES` if the basement was shown; otherwise, `NO`.
 */
- (void)cell:(BMXSwipableCell *)cell basementVisibilityChanged:(BOOL)showing;

@end



@interface BMXSwipableCell : UITableViewCell <UIScrollViewDelegate>


///------------------------------------------------
/// @name Configuring cell options
///------------------------------------------------

/**
 Allowed space for cell sliding
 
 @discussion Width of scrollable area. Usually it is equal to the width of the contents stored in the basement view, but can be any larger if a different dragging feel is desired.
 */
@property (nonatomic, assign) CGFloat basementVisibleWidth;

/**
 Support property that let the caller flag the cell basement as already configured
 
 @discussion When cells are reused, previous basement subviews are already in place, so the client logic could use this property to avoid creation of new basement content. This property allows to avoid associated objects or tagging of the cell or its subviews.
 */
@property (nonatomic, assign) BOOL basementConfigured;


///------------------------------------------------
/// @name State inquiry and delegate support
///------------------------------------------------

/**
 Tells if the cell is currently showing the basement
 
 @discussion `YES` if the menu was shown; otherwise, `NO`.
 */
@property (nonatomic, assign, readonly) BOOL showingBasement;

/**
 The object that acts as the delegate of the receiving cell.
 
 @discussion The delegate can adopt the `BMXSwipableCellDelegate` protocol.
 */
@property (nonatomic, weak) id<BMXSwipableCellDelegate> delegate;


///------------------------------------------------
/// @name Accessing Cell View
///------------------------------------------------


/**
 Hosting scroll view
 
 @discussion Scroll View used to implement the "swipe to reveal" effect.
 */
@property (nonatomic, strong, readonly) UIScrollView *scrollView;

/**
 Hosting content view
 
 @discussion This view host the contents of the cell. On initialization the cell contents defined in Interface Builer are moved into it.
 */
@property (nonatomic, strong, readonly) UIView *scrollViewContentView;

/**
 Basement view
 
 @discussion The basement view is the area that can host user content, that can be UIButtons or custom views.
 */
@property (nonatomic, strong, readonly) UIView *basementView;


/**
 Swipe enabled

 @discussion Defines if swipe enabled for current cell. Enabled by default.
 */
@property (nonatomic, assign) BOOL swipeEnabled;


///------------------------------------------------
/// @name Class Methods
///------------------------------------------------

/**
 Restore initial state for all cells, closing the basement.
 
 @discussion
 */
+ (void)coverBasementOfAllCells;

@end
