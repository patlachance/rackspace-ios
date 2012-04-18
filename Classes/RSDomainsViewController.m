//
//  RSDomainsViewController.m
//  OpenStack
//
//  Created by Mike Mayo on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RSDomainsViewController.h"
#import "OpenStackAccount.h"
#import "AccountManager.h"
#import "RSDomain.h"
#import "UIViewController+Conveniences.h"
#import "RSAddDomainViewController.h"
#import "RSDomainViewController.h"

@implementation RSDomainsViewController

@synthesize account, tableView;

- (id)initWithAccount:(OpenStackAccount *)anAccount {
    self = [self initWithNibName:@"RSDomainsViewController" bundle:nil];
    if (self) {
        self.account = anAccount;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Domains";
    [self addAddButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.tableView = nil;
}

#pragma mark - Table View Data Source and Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.account.domains count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    RSDomain *rsDomain = [[self.account sortedDomains] objectAtIndex:indexPath.row];
    cell.textLabel.text = rsDomain.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RSDomain *domain = [[self.account sortedDomains] objectAtIndex:indexPath.row];
    RSDomainViewController *vc = [[RSDomainViewController alloc] initWithAccount:self.account domain:domain];
    [self presentPrimaryViewController:vc];
    [vc release];
    
}

#pragma mark - Button Handlers

- (IBAction)refreshButtonPressed:(id)sender {
    
    [self showToolbarActivityMessage:@"Refreshing domains..."];
    
    [[self.account.manager getDomains] success:^(OpenStackRequest *request) {
        
        [self hideToolbarActivityMessage];
        [self.tableView reloadData];
        
    } failure:^(OpenStackRequest *request) {
        
        [self hideToolbarActivityMessage];
        [self alert:@"There was a problem loading your domains." request:request];
        
    }];
    
}

- (void)addButtonPressed:(id)sender {
    
    RSAddDomainViewController *vc = [[RSAddDomainViewController alloc] initWithAccount:self.account];
    [self presentModalViewControllerWithNavigation:vc];
    [vc release];
    
}

#pragma mark - Memory Management

- (void)dealloc {
    [account release];
    [super dealloc];
}

@end
