//
//  BMXViewController.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXSwipableCell+ConfigureCell.h"
#import "BMXViewController.h"
#import "UITableViewCell+ConfigureCell.h"
#import "UITableViewController+BMXSwipableCellSupport.h"


@implementation BMXViewController {
    NSMutableArray *_data;
    NSString *_cellIdentifier;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    // toolbar
    //
    self.navigationController.toolbarHidden = NO;
    
    UIBarButtonItem *editSelectionModeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Selection mode"
                                                           style: UIBarButtonItemStylePlain
                                                          target: self
                                                          action: @selector(selectionButtonTapped:)];
    
    UIBarButtonItem *editCellTypeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Cell Type"
                                                                                  style: UIBarButtonItemStylePlain
                                                                                 target: self
                                                                                 action: @selector(editCellTypeButtonTapped:)];
    UIBarButtonItem *editEditSelectionModeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Edit Selection mode"
                                                           style: UIBarButtonItemStylePlain
                                                          target: self
                                                          action: @selector(editingSelectionButtonTapped:)];
    UIBarButtonItem *spaceBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                  target: nil
                                                  action: nil];
    
    self.toolbarItems = @[editSelectionModeBarButtonItem,
                          spaceBarButtonItem,
                          editCellTypeBarButtonItem,
                          spaceBarButtonItem,
                          editEditSelectionModeBarButtonItem];
    
    //
    _data = [[NSMutableArray alloc] init];
    _cellIdentifier = @"SwipeCell";
}

- (void)selectionButtonTapped:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle: @"Choose selection mode for viewing"
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                         destructiveButtonTitle: nil
                                              otherButtonTitles: @"No selection", @"Single selection", @"Multiple selection", nil];

    sheet.tag = 1;
    [sheet showFromToolbar: self.navigationController.toolbar];
}

- (void)editCellTypeButtonTapped:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle: @"Choose cell type"
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                         destructiveButtonTitle: nil
                                              otherButtonTitles: @"Swipe", @"Default", nil];
    
    sheet.tag = 2;
    [sheet showFromToolbar: self.navigationController.toolbar];
}

- (void)editingSelectionButtonTapped:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle: @"Choose selection mode for editing"
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                         destructiveButtonTitle: nil
                                              otherButtonTitles: @"No selection", @"Single selection", @"Multiple selection", nil];
    
    sheet.tag = 3;
    [sheet showFromToolbar: self.navigationController.toolbar];
}


#pragma - Actions

- (IBAction)addButtonTapped:(id)sender
{
    [_data insertObject:[NSDate date] atIndex:0];
    
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
	[self.tableView insertRowsAtIndexPaths: @[indexPath]
                          withRowAnimation: UITableViewRowAnimationAutomatic];
}

- (IBAction)editButtonTapped:(id)sender
{
    self.tableView.editing = !self.tableView.editing;
}


#pragma - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 1:
        {
            switch (buttonIndex) {
                case 0:
                    self.tableView.allowsSelection = NO;
                    break;
                case 1:
                    self.tableView.allowsSelection = YES;
                    self.tableView.allowsMultipleSelection = NO;
                    break;
                case 2:
                    self.tableView.allowsSelection = YES;
                    self.tableView.allowsMultipleSelection = YES;
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        case 2:
            if (buttonIndex == 0) {
                _cellIdentifier = @"SwipeCell";
            } else {
                _cellIdentifier = @"DefaultCell";
            }
            [self.tableView reloadData];
            break;
            
        case 3:
        {
            switch (buttonIndex) {
                case 0:
                    self.tableView.allowsSelectionDuringEditing = NO;
                    break;
                case 1:
                    self.tableView.allowsSelectionDuringEditing = YES;
                    self.tableView.allowsMultipleSelectionDuringEditing = NO;
                    break;
                case 2:
                    self.tableView.allowsSelectionDuringEditing = YES;
                    self.tableView.allowsMultipleSelectionDuringEditing = YES;
                    break;
                    
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
}


#pragma - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier: _cellIdentifier
                                                                               forIndexPath: indexPath];
    
	NSDate *object = _data[indexPath.row];
    [cell configureCellForItem: object];
    
    if ([cell isKindOfClass:[BMXSwipableCell class]]) {
        ((BMXSwipableCell*)cell).delegate = self;
    }

	return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
#warning not implemented in this demo
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell %@ highlighted", [self cellDescriptionForRow: indexPath.row]);
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell %@ unhighlighted", [self cellDescriptionForRow: indexPath.row]);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell %@ will select", [self cellDescriptionForRow: indexPath.row]);
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell %@ selected", [self cellDescriptionForRow: indexPath.row]);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell %@ will deselect", [self cellDescriptionForRow: indexPath.row]);
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell %@ deselected", [self cellDescriptionForRow: indexPath.row]);
}

- (NSString*)cellDescriptionForRow:(NSUInteger)row
{
    NSDate *date = [_data objectAtIndex: row];
    NSString *temp = [NSString stringWithFormat: @"%16f", [date timeIntervalSince1970]];
    return [temp substringFromIndex: 11];
}

#pragma mark - BMXSwipableCellDelegate

- (void)cell:(BMXSwipableCell *)cell basementVisibilityChanged:(BOOL)showing
{
    NSLog(@"cell %@ now %@",
          cell.textLabel.text,
          (showing ? @"visible" : @"not visible"));
}




@end
