//
//  $Id$
//
//  SPStringAdditions.m
//  sequel-pro
//
//  Created by Stuart Connolly (stuconnolly.com) on Jan 28, 2009
//  Copyright (c) 2009 Stuart Connolly. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//  More info at <http://code.google.com/p/sequel-pro/>

#import "SPStringAdditions.h"
#import "RegexKitLite.h"

@interface NSString (Private)
- (int)smallestOf:(int)a andOf:(int)b andOf:(int)c;
@end

@implementation NSString (SPStringAdditions)

/*
 * Returns a human readable version string of the supplied byte size.
 */
+ (NSString *)stringForByteSize:(int)byteSize
{
	float size = byteSize;
	
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	
	if (size < 1023) {
		[numberFormatter setFormat:@"#,##0 B"];
		
		return [numberFormatter stringFromNumber:[NSNumber numberWithInt:size]];
	}
	
	size = (size / 1024);
	
	if (size < 1023) {
		[numberFormatter setFormat:@"#,##0.0 KB"];
		
		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:size]];
	}
	
	size = (size / 1024);
	
	if (size < 1023) {
		[numberFormatter setFormat:@"#,##0.0 MB"];
		
		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:size]];
	}
	
	size = (size / 1024);
	
	[numberFormatter setFormat:@"#,##0.0 GB"];
	
	return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:size]];
}


// -------------------------------------------------------------------------------
// stringForTimeInterval:
//
// Returns a human readable version string of the supplied time interval.
// -------------------------------------------------------------------------------
+ (NSString *)stringForTimeInterval:(float)timeInterval
{
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];

	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

	// For time periods of less than one millisecond, display a localised "< 0.1 ms"
	if (timeInterval < 0.0001) {
		[numberFormatter setFormat:@"< #,##0.0 ms"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:0.1]];
	}

	if (timeInterval < 0.1) {
		timeInterval = (timeInterval * 1000);
		[numberFormatter setFormat:@"#,##0.0 ms"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
	}
	if (timeInterval < 1) {
		timeInterval = (timeInterval * 1000);
		[numberFormatter setFormat:@"#,##0 ms"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
	}
	
	if (timeInterval < 10) {
		[numberFormatter setFormat:@"#,##0.00 s"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
	}

	if (timeInterval < 100) {
		[numberFormatter setFormat:@"#,##0.0 s"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
	}

	if (timeInterval < 300) {
		[numberFormatter setFormat:@"#,##0 s"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
	}

	if (timeInterval < 3600) {
		timeInterval = (timeInterval / 60);
		[numberFormatter setFormat:@"#,##0 min"];

		return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
	}

	timeInterval = (timeInterval / 3600);
	[numberFormatter setFormat:@"#,##0 hours"];

	return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:timeInterval]];
}


// -------------------------------------------------------------------------------
// backtickQuotedString
//
// Returns the string quoted with backticks as required for MySQL identifiers
// eg.:  tablename    =>   `tablename`
//       my`table     =>   `my``table`
// -------------------------------------------------------------------------------
- (NSString *)backtickQuotedString
{
	// mutableCopy automatically retains the returned string, so don't forget to release it later...
	NSMutableString *workingCopy = [self mutableCopy];

	// First double all backticks in the string to escape them
	// I don't want to use "stringByReplacingOccurrencesOfString:withString:" because it's only available in 10.5
	[workingCopy replaceOccurrencesOfString: @"`"  
                                  withString: @"``" 
                                     options: NSLiteralSearch 
                                       range: NSMakeRange(0, [workingCopy length]) ];
                                       
	// Add the quotes around the string
	NSString *quotedString = [NSString stringWithFormat: @"`%@`", workingCopy];

	[workingCopy release];

	return quotedString;
}

// -------------------------------------------------------------------------------
// tickQuotedString
//
// Returns the string quoted with ticks as required for MySQL identifiers
// eg.:  tablename    =>   'tablename'
//       my'table     =>   'my''table'
// -------------------------------------------------------------------------------
- (NSString *)tickQuotedString
{
	// mutableCopy automatically retains the returned string, so don't forget to release it later...
	NSMutableString *workingCopy = [self mutableCopy];
	
	// First double all backticks in the string to escape them
	// I don't want to use "stringByReplacingOccurrencesOfString:withString:" because it's only available in 10.5
	[workingCopy replaceOccurrencesOfString: @"'"  
								 withString: @"''" 
									options: NSLiteralSearch 
									  range: NSMakeRange(0, [workingCopy length]) ];
	
	// Add the quotes around the string
	NSString *quotedString = [NSString stringWithFormat: @"'%@'", workingCopy];
	
	[workingCopy release];
	
	return quotedString;
}

- (NSString *)replaceUnderscoreWithSpace
{
	NSMutableString *workingCopy = [self mutableCopy];
	[workingCopy replaceOccurrencesOfString:@"_"
								 withString:@" "
									options:NSLiteralSearch
									 range:NSMakeRange(0, [workingCopy length])];
	return [workingCopy autorelease];
}

// -------------------------------------------------------------------------------
// createViewSyntaxPrettifier
//
// Returns a 'CREATE VIEW SYNTAX' string a bit more readable
// If the string doesn't match it returns the unchanged string.
// -------------------------------------------------------------------------------
- (NSString *)createViewSyntaxPrettifier
{
	NSRange searchRange = NSMakeRange(0, [self length]);
	NSRange matchedRange;
	NSError *err = NULL;
	NSMutableString *tblSyntax = [NSMutableString stringWithCapacity:[self length]];
	NSString * re = @"(.*?) AS select (.*?) (from.*)";
	
	// create view syntax
	matchedRange = [self rangeOfRegex:re options:(RKLMultiline|RKLDotAll) inRange:searchRange capture:1 error:&err];
	
	if(!matchedRange.length || matchedRange.length > [self length]) return([self description]);
	
	[tblSyntax appendString:[self substringWithRange:matchedRange]];
	[tblSyntax appendString:@"\nAS select\n   "];
	
	// match all column definitions, split them by ',', and rejoin them by '\n'
	matchedRange = [self rangeOfRegex:re options:(RKLMultiline|RKLDotAll) inRange:searchRange capture:2 error:&err];
	
	if(!matchedRange.length || matchedRange.length > [self length]) return([self description]);
	
	[tblSyntax appendString:
		[[[self substringWithRange:matchedRange] componentsSeparatedByString:@"`,`"] componentsJoinedByString:@"`,\n   `"]];
	
	// from ... at a new line
	matchedRange = [self rangeOfRegex:re options:(RKLMultiline|RKLDotAll) inRange:searchRange capture:3 error:&err];
	
	if(!matchedRange.length || matchedRange.length > [self length]) return([self description]);
	
	[tblSyntax appendString:@"\n"];
	[tblSyntax appendString:[self substringWithRange:matchedRange]];
	
	// where clause at a new line if given
	[tblSyntax replaceOccurrencesOfString:@" where (" withString:@"\nwhere (" options:NSLiteralSearch range:NSMakeRange(0, [tblSyntax length])];
	
	return(tblSyntax);
}


// -------------------------------------------------------------------------------
// lineRangesForRange
//
// Returns an array of serialised NSRanges, each representing a line within the string
// which is at least partially covered by the NSRange supplied.
// Each line includes the line termination character(s) for the line.  As per
// lineRangeForRange, lines are split by CR, LF, CRLF, U+2028 (Unicode line separator),
// or U+2029 (Unicode paragraph separator).
// -------------------------------------------------------------------------------
- (NSArray *)lineRangesForRange:(NSRange)aRange
{
	NSMutableArray *lineRangesArray = [NSMutableArray array];
	NSRange currentLineRange;

	// Check that the range supplied is valid - if not return an empty array.
	if (aRange.location == NSNotFound || aRange.location + aRange.length > [self length])
		return lineRangesArray;

	// Get the range of the first string covered by the specified range, and add it to the array
	currentLineRange = [self lineRangeForRange:NSMakeRange(aRange.location, 0)];
	[lineRangesArray addObject:NSStringFromRange(currentLineRange)];

	// Loop through until the line end matches or surpasses the end of the specified range
	while (currentLineRange.location + currentLineRange.length < aRange.location + aRange.length) {
		currentLineRange = [self lineRangeForRange:NSMakeRange(currentLineRange.location + currentLineRange.length, 0)];
		[lineRangesArray addObject:NSStringFromRange(currentLineRange)];
	}

	// Return the constructed array of ranges
	return lineRangesArray;
}


#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
/*
 * componentsSeparatedByCharactersInSet:
 * Credit - Greg Hulands <ghulands@mac.com>
 * Needed for 10.4+ compatibility
 */
- (NSArray *)componentsSeparatedByCharactersInSet:(NSCharacterSet *)set // 10.5 adds this to NSString, but we are 10.4+
{ 
	NSMutableArray *result = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSString *chunk = nil;
	
	[scanner setCharactersToBeSkipped:nil];
	BOOL sepFound = [scanner scanCharactersFromSet:set intoString:(NSString **)nil]; // skip any preceding separators
	
	if (sepFound) { // if initial separator, start with empty component
		[result addObject:@""];
	}
	
	while ([scanner scanUpToCharactersFromSet:set intoString:&chunk]) {
		[result addObject:chunk];
		sepFound = [scanner scanCharactersFromSet: set intoString: (NSString **) nil];
	}
	
	if (sepFound) { // if final separator, end with empty component
		[result addObject: @""];
	}
	
	result = [result copy];
	return [result autorelease];
}
#endif


- (NSString *)stringByRemovingCharactersInSet:(NSCharacterSet*) charSet options:(unsigned) mask
{
	NSRange                 range;
	NSMutableString*        newString = [NSMutableString string];
	unsigned                len = [self length];
	
	mask &= ~NSBackwardsSearch;
	range = NSMakeRange (0, len);
	
	while (range.length)
	{
		NSRange substringRange;
		unsigned pos = range.location;
		
		range = [self rangeOfCharacterFromSet:charSet options:mask range:range];
		if (range.location == NSNotFound)
			range = NSMakeRange (len, 0);
		
		substringRange = NSMakeRange (pos, range.location - pos);
		[newString appendString:[self 
								 substringWithRange:substringRange]];
		
		range.location += range.length;
		range.length = len - range.location;
	}
	
	return newString;
}


- (NSString *)stringByRemovingCharactersInSet:(NSCharacterSet*) charSet
{
	return [self stringByRemovingCharactersInSet:charSet options:0];
}

// calculate the distance between two string case-insensitively
- (float)levenshteinDistanceWithWord:(NSString *)stringB
{
	// normalize strings
	NSString * stringA = [NSString stringWithString: self];
	[stringA stringByTrimmingCharactersInSet:
	[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[stringB stringByTrimmingCharactersInSet:
	[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringA = [stringA lowercaseString];
	stringB = [stringB lowercaseString];

	int k, i, j, cost, * d, distance;

	int n = [stringA length];
	int m = [stringB length];	

	if( n++ != 0 && m++ != 0 ) {

		d = malloc( sizeof(int) * m * n );

		for( k = 0; k < n; k++)
			d[k] = k;

		for( k = 0; k < m; k++)
			d[ k * n ] = k;

		for( i = 1; i < n; i++ )
		for( j = 1; j < m; j++ ) {

			if( [stringA characterAtIndex: i-1] == [stringB characterAtIndex: j-1] )
				cost = 0;
			else
				cost = 1;

			d[ j * n + i ] = [self smallestOf: d [ (j - 1) * n + i ] + 1
				andOf: d[ j * n + i - 1 ] +  1
				andOf: d[ (j - 1) * n + i -1 ] + cost ];
		}

		distance = d[ n * m - 1 ];

		free( d );

		return distance;
	}
	return 0.0;
}

// return the minimum of a, b and c
- (int)smallestOf:(int)a andOf:(int)b andOf:(int)c
{
	int min = a;
	if ( b < min )
		min = b;

	if( c < min )
		min = c;

	return min;
}


@end
