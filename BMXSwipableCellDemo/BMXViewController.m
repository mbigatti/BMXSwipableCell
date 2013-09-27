//
//  BMXViewController.m
//  BMXSwipableCellDemo
//
//  Created by Massimiliano Bigatti on 25/09/13.
//  Copyright (c) 2013 Massimiliano Bigatti. All rights reserved.
//

#import "BMXViewController.h"
#import "BMXSwipableCell+ConfigureCell.h"
#import "UITableViewController+BMXSwipableCellSupport.h"


@implementation BMXViewController {
    NSMutableArray *_data;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _data = [[NSMutableArray alloc] init];
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


#pragma - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	BMXSwipableCell *cell = (BMXSwipableCell *)[tableView dequeueReusableCellWithIdentifier: @"Cell"
                                                                               forIndexPath: indexPath];
    
	NSDate *object = _data[indexPath.row];
    [cell configureCellForItem: object];
    
    cell.delegate = self;

	return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
#warning not implemented
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell selected");
}


#pragma mark - BMXSwipableCellDelegate

- (void)cell:(BMXSwipableCell *)cell basementVisibilityChanged:(BOOL)showing
{
    NSLog(@"cell %@ now %@",
          cell.textLabel.text,
          (showing ? @"visible" : @"not visible"));
}




@end
