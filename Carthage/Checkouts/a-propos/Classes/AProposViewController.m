//
//  AProposViewController.m
//
//  Created by Lis@cintosh on 10/01/2017.
//
//

#import "AProposViewController.h"

#define LocalizedString(key, default) \
	[NSBundle.mainBundle localizedStringForKey:(key) value:(default) table:nil]

NSString * identifierForLicenseType(ApplicationLicenseType licenseType) {
	switch (licenseType) {
		case ApplicationLicenseTypeMIT:		return @"a-propos.license.mit";
		case ApplicationLicenseTypeGNU:		return @"a-propos.license.gnu3.0";
		case ApplicationLicenseTypeApache:	return @"a-propos.license.apache";
		case ApplicationLicenseTypeApache2: return @"a-propos.license.apache2.0";
		case ApplicationLicenseTypePublicDomain: return @"a-propos.license.public-domain";
		default: break;
	}
	return nil;
}

NSString * descriptionForLicenseType(ApplicationLicenseType licenseType) {
	switch (licenseType) {
		case ApplicationLicenseTypeMIT:		return @"MIT";
		case ApplicationLicenseTypeGNU:		return @"GNU General Public 3.0";
		case ApplicationLicenseTypeApache:	return @"Apache";
		case ApplicationLicenseTypeApache2: return @"Apache 2.0";
		case ApplicationLicenseTypePublicDomain: return @"public domain";
		default: break;
	}
	return nil;
}

NSString * localizedDescriptionForLicenseType(ApplicationLicenseType licenseType) {
	return LocalizedString(identifierForLicenseType(licenseType),
						   descriptionForLicenseType(licenseType)); // Fallback to default description if no localization file found
}

@implementation NSDate (YearAddition)

- (NSInteger)ap_year
{
	NSCalendar * calendar = [NSCalendar currentCalendar];
	return [calendar component:NSCalendarUnitYear fromDate:self];
}

@end

@implementation NSURL (FormatAddition)

- (NSString *)ap_shortDescription
{
	return [self.host stringByAppendingString:self.path];
}

@end

@implementation AProposViewController

- (instancetype)initWithLicenseType:(ApplicationLicenseType)licenseType
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.licenseType = licenseType;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = LocalizedString(@"a-propos.title", @"About");
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						  target:self action:@selector(doneAction:)];
	
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cellID"];
}

- (void)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Accessors

- (void)setUrls:(NSArray<NSURL *> *)urls
{
	_urls = urls;
	[self.tableView reloadData];
}

- (void)setURLsStrings:(NSArray <NSString *> *)urlStrings
{
	NSMutableArray <NSURL *> * urls = [[NSMutableArray alloc] initWithCapacity:urlStrings.count];
	for (__strong NSString * urlString in urlStrings) {
		if (![urlString containsString:@"://"]) {
			urlString = [@"https://" stringByAppendingString:urlString];
		}
		[urls addObject:[NSURL URLWithString:urlString]];
	}
	self.urls = urls;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2 + (_licenseType != ApplicationLicenseTypePrivate) /* Top header informations, web links, license details (if not private) */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0: return 0;
		case 1: return _urls.count;
		case 2: return 1;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSDictionary * infoDictionary = [NSBundle mainBundle].infoDictionary;
	NSString * name = infoDictionary[(__bridge NSString *)kCFBundleExecutableKey];
	switch (section) {
		case 0: {
			const NSString * shortVersion = infoDictionary[@"CFBundleShortVersionString"];
			NSString * nameString = [NSString stringWithFormat:@"%@ %@", name, shortVersion];
			if (_showsBuildNumber) {
				const NSString * buildVersion = infoDictionary[(__bridge_transfer NSString *)kCFBundleVersionKey];
				nameString = [nameString stringByAppendingFormat:@" (%@)", buildVersion];
			}
			return [nameString stringByAppendingFormat:@"\n" @"%@, %lu", _author, (unsigned long)[NSDate date].ap_year];
		}
		case 2: {
			return [NSString stringWithFormat:LocalizedString(@"a-propos.license.description", @"%@ is an open-source projet, under %@ license."),
					name, localizedDescriptionForLicenseType(_licenseType)];
		}
		default: break;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	if (indexPath.section == 1) {
		cell.textLabel.text = _urls[indexPath.row].ap_shortDescription;
	}
	else if (indexPath.section == 2) {
		cell.textLabel.text = _repositoryURL.ap_shortDescription;
	}
	return cell;
}

#pragma mark - Table view delegate

- (void)openURL:(NSURL *)url
{
	if (NSClassFromString(@"SFSafariViewController")) {
		SFSafariViewController * viewController = [[SFSafariViewController alloc] initWithURL:url];
		[self presentViewController:viewController animated:YES completion:nil];
	} else {
		if ([UIApplication instancesRespondToSelector:@selector(openURL:options:completionHandler:)]) {
			[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
		} else {
			[[UIApplication sharedApplication] openURL:url];
		}
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1) {
		[self openURL:_urls[indexPath.row]];
	}
	else if (indexPath.section == 2) {
		[self openURL:_repositoryURL];
	}
}

@end

#undef LocalizedString
