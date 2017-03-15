//
//  AProposViewController.h
//
//  Created by Lis@cintosh on 10/01/2017.
//
//

@import SafariServices;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ApplicationLicenseType) {
	/// No license or closed source project license
	ApplicationLicenseTypePrivate = 0,
	
	/// Massachusetts Institute of Technology (MIT) license
	/// https://opensource.org/licenses/MIT
	ApplicationLicenseTypeMIT,
	
	/// GNU General Public License 3.0 license
	/// https://opensource.org/licenses/gpl-3.0
	ApplicationLicenseTypeGNU,
	
	/// Apache Software License 1.1 license
	/// https://opensource.org/licenses/Apache-1.1
	ApplicationLicenseTypeApache,
	
	/// Apache License, Version 2.0 license
	/// https://opensource.org/licenses/Apache-2.0
	ApplicationLicenseTypeApache2,
	
	/// Public domain license
	/// https://en.wikipedia.org/wiki/Public_domain
	ApplicationLicenseTypePublicDomain
};

/**
 Returns localizable license identifier.
 */
extern NSString * _Nullable identifierForLicenseType(ApplicationLicenseType licenseType);

/**
 Returns non-localized license description.
 */
extern NSString * _Nullable descriptionForLicenseType(ApplicationLicenseType licenseType);

/**
 Returns localized license description.
 */
extern NSString * _Nullable localizedDescriptionForLicenseType(ApplicationLicenseType licenseType);

@interface AProposViewController : UITableViewController

/**
 Type of license for the application; default to private license.
 See `ApplicationlicenseType` for supported types.
*/
@property (nonatomic, assign) ApplicationLicenseType licenseType;

/**
 If true, displays build number next to app version.
 Default to false.
 */
@property (nonatomic, assign) BOOL showsBuildNumber;

/**
 Human-readable name of the application author. Required.
 */
@property (nonatomic, strong) NSString * author;

/**
 List of web links URLs to display.
 */
@property (nonatomic, strong) NSArray <NSURL *> * urls;

/**
 URL of the repository (Github, etc.) for open source project.
 */
@property (nonatomic, strong, nullable) NSURL * repositoryURL;

/*
 Returns a newly initialized view controller with specified license.
 See `ApplicationlicenseType` for supported types.
 */
- (instancetype)initWithLicenseType:(ApplicationLicenseType)licenseType;

/**
 Set web links URLs with array of string, including or not the URL scheme.
 If ths scheme is missing, `https://` scheme is used.
 */
- (void)setURLsStrings:(NSArray <NSString *> *)urlStrings;

@end

NS_ASSUME_NONNULL_END
