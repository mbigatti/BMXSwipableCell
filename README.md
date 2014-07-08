# BMXSwipableCell

A custom `UITableViewCell` that supports cell dragging gesture to reveal a custom menu of buttons or other views. It supports:

- fully customizable `UIView` to use as a canvas for custom buttons and views;
- Auto Layout;
- storyboards;
- easy cell reuse;
- highlight / unhighlight of cells;
- selection / deselection of cells;
- normal and edit mode;
- accessory views;
- compatible with iOS 7 and 8.

`BMXSwipableCell` try to mimic the original behaviour of iOS7 Mail App by all aspects.

![image](http://f.cl.ly/items/0U1r411v2B0J1t142n1P/demo.gif)

BMXSwipableCell is storyboard-friendly as does not implements cell contents on its own but uses the elements defined in Interface Builder. It is of course possible to implement the content by code.

![image](http://f.cl.ly/items/0e011T2u373f0p2m1S3y/Interface%20Builder.png)

`BMXSwipableCell` is generic in terms of what to show when a cell is swiped. It could be two buttons, one buttons or an entirely different content. For this reason `BMXSwipableCell` does not implement "More" and "Delete" buttons on its own, but it exports a _basement_ view, that is the view underneath the original content view defined in Interface Builder. In `tableView:cellForRowAtIndexPath` it is then possible to add the desidered buttons or view.

## Installation

### From CocoaPods

Add `pod 'BMXSwipableCell'` to your Podfile.

### Manually

Drag `BMXSwipableCellDemo/BMXSwipableCell` folder into your project and add it to your targets.


## Usage

1. If you're using Interface Builder, define the `Custom Class` of the cell as `BMXSwipableCell`. If you're going by code, register `BMXSwipableCell` with your `UITableView`.
2. Implement the `tableView:cellForRowAtIndexPath` method and configure the cell as desired. Here it is done by a category:

```objective-c
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
	BMXSwipableCell *cell = (BMXSwipableCell *)
	    [tableView dequeueReusableCellWithIdentifier: @"Cell"
	                                    forIndexPath: indexPath];
    
	[cell configureCellForItem: [_data objectAtIndex: indexPath.row]];

	return cell;
} 
```

Before adding subviews to the basement you can check if the cell was already initialized using the property `basementConfigured` (cell that get reused can already have the custom basement content):

```objective-c
@implementation BMXSwipableCell (ConfigureCell)

- (void)configureCellForItem:(BMXDataItem*)item
{
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    CGFloat x = self.basementVisibleWidth - cellHeight * 2;
    
    //
    // configure cell only if not already done
    //
    if (!self.basementConfigured) {    
	    // first button...
    
    	//
    	// delete button
    	//
	    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	    deleteButton.backgroundColor = 
	    	[UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0f];
	    deleteButton.frame = CGRectMake(x + cellHeight, 0, cellHeight, cellHeight);
	    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
	    [deleteButton setTitleColor:[UIColor whiteColor] 
	    					forState: UIControlStateNormal];
	    [deleteButton addTarget: self
	                     action: @selector(userPressedDeleteButton:)
	           forControlEvents: UIControlEventTouchUpInside];
	    
	    [self.basementView addSubview: deleteButton];
    }
    
    // configure cell contents

}
//... more
```

3. Add few methods to your `UITableViewController` / `UITableViewDelegate` to manage automatic hiding of basements when device is rotated or when the list is scrolled:

```objective-c
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                duration:(NSTimeInterval)duration 
{
    
    [super willRotateToInterfaceOrientation: toInterfaceOrientation
                                   duration: duration];
    
    [BMXSwipableCell coverBasementOfAllCells];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [BMXSwipableCell coverBasementOfAllCells];
}
```

This code is also available in the `UITableViewController+BMXSwipableCellSupport` category for your convenience.

**Check out the sample project for a complete usage example.**

## Notes about Interface Builder
1. Remember to set `Custom Class` to `BMXSwipableCell`.
2. To always get correct background colors (both in normal and editing modes), configure the `Background` property in both cell and content view.

## Acknowledgements

- Original idea, tutorial and code by Ash Furrow - [UITableViewCell-Swipe-for-Options](https://github.com/TeehanLax/UITableViewCell-Swipe-for-Options)
- Strategy to be able to let UITableView / UITableViewCell do the highlight / selection by richardmarktl - [SMMoreOptionsCell](https://github.com/richardmarktl/SMMoreOptionsCell)

### Contact
[http://bigatti.it](http://bigatti.it)  
[@mbigatti](https://twitter.com/mbigatti)
