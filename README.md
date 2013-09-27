# BMXSwipableCell

A custom UITableViewCell that supports swipe to reveal, based on [code](https://github.com/TeehanLax/UITableViewCell-Swipe-for-Options) and
tutorial by Ash Furrow and other contributors. This implementation try to mimic the iOS7 Mail app, including automatic selection / deselection
of rows based on user actions.

![image](http://f.cl.ly/items/3H400Z030Z3A1w2N3H3W/test.gif)

BMXSwipableCell is storyboard-friendly as does not implements cell contents on its own but uses the elements defined in Interface Builder. It is of course possible to implement the content by code.

![image](http://f.cl.ly/items/0e011T2u373f0p2m1S3y/Interface%20Builder.png)

BMXSwipableCell is generic in terms of what to show when a cell is swiped. It could be two buttons, one buttons or an entirely different content. For this reason BMXSwipableCell does not implement "More" and "Delete" buttons on its own, but it exports a _basement_ view, that is the view underneath the original content view defined in Interface Builder. In `tableView:cellForRowAtIndexPath` it is then possible to add the desidered buttons or view.

## Installation

### From CocoaPods

Add `pod 'BMXSwipableCell'` to your Podfile.

### Manually

Drag `BMXSwipableCellDemo/BMXSwipableCell` folder into your project and add it to your targets.


## Usage

1. If you're using Interface Builder, define the `Custom Class` of the cell as `BMXSwipableCell`. If you're going by code, register `BMXSwipableCell` with your `UITableView`.
2. Implement the `tableView:cellForRowAtIndexPath` method and configure the cell as desired. Here it is done by a category:

```objective-c
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	BMXSwipableCell *cell = (BMXSwipableCell *)[tableView dequeueReusableCellWithIdentifier: @"Cell"
                                                                               forIndexPath: indexPath];
    
	NSDate *object = _data[indexPath.row];
    [cell configureCellForItem: object];

	return cell;
} 
```

Before adding subviews to the basement you can check if the cell was already initialized using the property `basementConfigured` (cell that get reused can already have the custom basement content):

```objective-c
@implementation BMXSwipableCell (ConfigureCell)

- (void)configureCellForItem:(NSDate*)date
{
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    CGFloat x = self.catchWidth - cellHeight * 2;
    
    //
    // configure cell only if not already done
    //
    if (!self.basementConfigured) {    
	    // first button...
    
    	//
    	// delete button
    	//
	    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	    deleteButton.backgroundColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0f];
	    deleteButton.frame = CGRectMake(x + cellHeight, 0, cellHeight, cellHeight);
	    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
	    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	    [deleteButton addTarget: self
	                     action: @selector(userPressedDeleteButton:)
	           forControlEvents: UIControlEventTouchUpInside];
	    
	    [self.basementView addSubview: deleteButton];
    }
    
    // configure cell contents

}
//... more
```

**Check out the sample project for a complete usage example.**

## Notes about Interface Builder
1. Accessory view are not supported and those have to be implemented in the content view of the cell.
2. Remeber to set `Custom Class` to `BMXSwipableCell`.
3. To always get correct background colors (both in normal and editing modes), configure the `Background` property in both cell and content view.
4. If you are using a cell with not visible content (for example a cell with two labels one of which has `text = nil`) and you update that same cell setting a visible value, UIKit creates the label in the cell content view after `BMXSwipeCell` initializing code, so when you drag the cell the new created label does not scroll with other cell content. A workaround to this issue is to assign the `text` property of the cell to a space. In this way the label will be created at startup and transferred to the scroll view.

## Contact

- [Web](http://bigatti.it) 
- [Twitter](https://twitter.com/mbigatti)

## License

### MIT License
Copyright (c) 2013 Massimiliano Bigatti (http://bigatti.it)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
