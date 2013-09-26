//
//  GuideXML.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideXML.h"
#import "RXMLElement+Helpers.h"

@implementation GuideXML
@synthesize title = _title;
@synthesize desc = _desc;
@synthesize compiler = _compiler;
@synthesize license = _license;
@synthesize dirPath = _dirPath;
@synthesize xmlPath = _xmlPath;
@synthesize xmlURL = _xmlURL;
@synthesize ngzPath = _ngzPath;
@synthesize ngzURL = _ngzURL;
@synthesize filePath = _filePath;
@synthesize identifier = _identifier;


+ (id)elementFromXMLFilePath:(NSString *)fullPath {
    return [[GuideXML alloc] initFromXMLFilePath:fullPath];
}

// clone with new xml data but preserve the identifier
- (GuideXML *)cloneWithXMLFilePath:(NSString *)path
{
    GuideXML *g = [[GuideXML alloc] initFromXMLFilePath:path];
    g.identifier = [self.identifier copy];
    return g;
}

- (id)initFromXMLFilePath:(NSString *)fullPath {
    self.filePath = fullPath;
    return (GuideXML *)[super initFromXMLFilePath:fullPath];
}

- (id)initWithIdentifier:(NSString *)identifier
{
    self.identifier = identifier;
    self = [super initFromXMLFilePath:self.xmlPath];
    if (!self) {
        self = [super init];
    }
    if (self) {
        self.identifier = identifier;
    }
    return self;
}

- (NSString *)identifier
{
    if (!_identifier) {
        _identifier = [[self child:@"INatGuide"] attribute:@"id"];
    }
    return _identifier;
}

- (NSString *)dirPath
{
    if (!_dirPath) {
        NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [docDirs objectAtIndex:0];
        NSString *guidesDirPath = [docDir stringByAppendingPathComponent:@"guides"];
        _dirPath = [guidesDirPath stringByAppendingPathComponent:self.identifier];
    }
    return _dirPath;
}

- (NSString *)xmlPath
{
    if (!_xmlPath) {
        _xmlPath = [self.dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", self.identifier]];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *fnames = [fm contentsOfDirectoryAtPath:self.dirPath error:nil];
        for (NSString *fname in fnames) {
            if ([fname rangeOfString:@".xml"].location != NSNotFound) {
                _xmlPath = [self.dirPath stringByAppendingPathComponent:fname];
                break;
            }
        }
    }
    return _xmlPath;
}

- (NSString *)ngzPath
{
    if (!_ngzPath) {
        _ngzPath = [self.dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ngz", self.identifier]];
    }
    return _ngzPath;
}

- (NSString *)title
{
    if (!_title) {
        _title = [self atXPath:@"//INatGuide/dc:title"].text;
    }
    return _title;
}

- (NSString *)desc
{
    if (!_desc) {
        _desc = [[self atXPath:@"//INatGuide/dc:description"] text];
    }
    if (!_desc || _desc.length == 0) _desc = NSLocalizedString(@"No description", nil);
    return _desc;
}

- (NSString *)compiler
{
    if (!_compiler) {
        _compiler = [[self atXPath:@"//INatGuide/eol:agent[@role='compiler']"] text];
    }
    if (!_compiler) {
        NSLocalizedString(@"Unknown", nil);
    }
    return _compiler;
}

- (NSString *)license
{
    if (!_license) {
        NSString *licenseURL = [[self atXPath:@"//INatGuide/dc:license"] text];
        if (licenseURL) {
            NSArray *pieces = [licenseURL componentsSeparatedByString:@"/"];
            if (pieces.count > 2) {
                _license = [[NSString stringWithFormat:@"CC %@", [pieces objectAtIndex:pieces.count - 3]] uppercaseString];
                
            }
        }
    }
    if (!_license) {
        NSLocalizedString(@"None, all rights reserved", nil);
    }
    return _license;
}

- (NSDate *)xmlDownloadedAt
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm attributesOfItemAtPath:self.xmlPath error:nil] fileCreationDate];
}

- (NSDate *)ngzDownloadedAt
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm attributesOfItemAtPath:self.ngzPath error:nil] fileCreationDate];
}

- (NSString *)imagePathForTaxonAtPosition:(NSInteger)position size:(NSString *)size fromXPath:(NSString *)xpath
{
    NSString *imgXPath = [NSString stringWithFormat:@"%@[%d]/GuidePhoto[1]/href[@type='local' and @size='%@']", xpath, position, size];
    RXMLElement *href = [self atXPath:imgXPath];
    if (href) {
        NSString *imgPath = [self.dirPath stringByAppendingPathComponent:href.text];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
            return imgPath;
        }
    }
    return nil;
}

- (NSString *)imageURLForTaxonAtPosition:(NSInteger)position size:(NSString *)size fromXPath:(NSString *)xpath
{
    RXMLElement *href = [self atXPath:
                              [NSString stringWithFormat:@"%@[%d]/GuidePhoto[1]/href[@type='remote' and @size='%@']", xpath, position, size]];
    return href.text;
}

- (NSString *)displayNameForTaxonAtPosition:(NSInteger)position fromXpath:(NSString *)xpath
{
    return [[self atXPath:[NSString stringWithFormat:@"(%@)[%d]/displayName", xpath, position]] text];
}
- (NSString *)nameForTaxonAtPosition:(NSInteger)position fromXpath:(NSString *)xpath
{
    return [[self atXPath:[NSString stringWithFormat:@"(%@)[%d]/name", xpath, position]] text];
}

- (NSString *)ngzFileSize
{
    return @"50.9 MB";
}

- (void)deleteNGZ
{
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:self.ngzPath error:nil];
    [fm removeItemAtPath:[self.dirPath stringByAppendingPathComponent:@"files"] error:nil];
}
@end
