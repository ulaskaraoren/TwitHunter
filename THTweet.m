//
//  Tweet.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSManagedObject+ST.h"
#import "NSString+TH.h"
#import "THTweet.h"
#import "THUser.h"

static NSRegularExpression *linksRegex = nil;
static NSRegularExpression *usernamesRegex = nil;
static NSRegularExpression *hashtagsRegex = nil;

@implementation THTweet

@dynamic text;
@dynamic uid;
@dynamic score;
@dynamic date;
@dynamic user;
@dynamic isRead;
@dynamic isFavorite;
//@dynamic containsURL;

static NSDateFormatter *createdAtDateFormatter = nil;

- (NSDateFormatter *)createdAtDateFormatter {
    
    if (createdAtDateFormatter == nil) {
        createdAtDateFormatter = [[NSDateFormatter alloc] init];
        
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [createdAtDateFormatter setLocale:usLocale];
        [createdAtDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [createdAtDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [createdAtDateFormatter setDateFormat: @"EEE MMM dd HH:mm:ss Z yyyy"];
    }
    
    return createdAtDateFormatter;
}

//- (NSAttributedString *)attributedString {
//
//    if(self.text == nil) return nil;
//
//    NSAttributedString *as = [[NSAttributedString alloc] initWithString:self.text];
//
//    return [as autorelease];
//}

- (NSNumber *)isFavoriteWrapper {
	return self.isFavorite;
}

- (void)setIsFavoriteWrapper:(NSNumber *)n {
	BOOL flag = [n boolValue];
	NSLog(@"-- set %d", flag);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:n forKey:@"value"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SetFavoriteFlagForTweet" object:self userInfo:userInfo];
	
	self.isFavorite = n;
	BOOL success = [self save];
	if(!success) NSLog(@"-- can't save");
}

+ (NSArray *)tweetsWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[THTweet entityInContext:context]];
	
	NSPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[request setPredicate:p];
	
	NSError *error = nil;
	
	NSArray *tweets = [context executeFetchRequest:request error:&error];
	
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return tweets;
}

+ (NSUInteger)tweetsCountWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[THTweet entityInContext:context]];
	
	NSPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[request setPredicate:p];
	
	NSError *error = nil;
	
	NSUInteger count = [context countForFetchRequest:request error:&error];
	
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return count;
}

+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context {
	NSPredicate *p = [NSPredicate predicateWithFormat:@"score == %@", aScore];
	NSArray *ps = [predicates arrayByAddingObject:p];
    
	NSUInteger count = [self tweetsCountWithAndPredicates:ps context:context];
    
    NSLog(@"-- score %@ -> %ld", aScore, count);
    
    return count;
}

+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword context:(NSManagedObjectContext *)context {
    
    NSAssert(keyword != nil, @"keyword should not be nil");
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"text contains[c] %@" argumentArray:[NSArray arrayWithObject:keyword]];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return array;
}

+ (THTweet *)tweetWithUid:(NSString *)uid context:(NSManagedObjectContext *)context {
    if(uid == nil) return nil;
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
	NSNumber *uidNumber = [NSNumber numberWithUnsignedLongLong:[uid unsignedLongLongValue]];
    
    //NSLog(@"--> %@", uidNumber);
    
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid == %@", uidNumber, nil];
	[request setPredicate:p];
	[request setFetchLimit:1];
	
	NSError *error = nil;
    
    NSLog(@"-- fetching tweet with uid: %@", uid);
    
    NSArray *array = [context executeFetchRequest:request error:&error];
	if(array == nil) {
		NSLog(@"-- error:%@", error);
	}
	
	return [array lastObject];
}

+ (THTweet *)tweetWithHighestUidInContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sd]];
	[request setFetchLimit:1];
	
	NSError *error = nil;
    
    NSArray *array = [context executeFetchRequest:request error:&error];
	if(array == nil) {
		NSLog(@"-- error:%@", error);
	}
    
    return [array lastObject];
}

+ (NSArray *)tweetsWithIdGreaterOrEqualTo:(NSNumber *)anId context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid >= %@", anId, nil];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	
	return array;
}

+ (void)unfavorFavoritesBetweenMinId:(NSNumber *)unfavorMinId maxId:(NSNumber *)unfavorMaxId context:(NSManagedObjectContext *)context {
	if([unfavorMinId isGreaterThanOrEqualTo:unfavorMaxId]) {
		NSLog(@"-- can't unfavor ids, given maxId is smaller than minId");
		return;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[THTweet entityInContext:context]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"isFavorite == YES AND uid <= %@ AND uid >= %@", unfavorMaxId, unfavorMinId, nil];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	
	for(THTweet *t in array) {
		t.isFavorite = [NSNumber numberWithBool:NO];
		NSLog(@"** unfavor %@", t.user.screenName);
	}
}

+ (THTweet *)updateOrCreateTweetFromDictionary:(NSDictionary *)d context:(NSManagedObjectContext *)context {
	
	NSString *uid = [d objectForKey:@"id"];
	
	BOOL wasCreated = NO;
	THTweet *tweet = [self tweetWithUid:uid context:context];
	if(!tweet) {
		tweet = [THTweet createInContext:context];
		wasCreated = YES;
		tweet.uid = [NSNumber numberWithUnsignedLongLong:[[d objectForKey:@"id"] unsignedLongLongValue]];
        
		NSDictionary *userDictionary = [d objectForKey:@"user"];
		THUser *user = [THUser getOrCreateUserWithDictionary:userDictionary context:context];
		
		NSMutableString *s = [NSMutableString stringWithString:[d objectForKey:@"text"]];
		[s replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		tweet.text = s;
		
        // if needed, use entities.urls to detect URLs
        /*
         "entities":
         {
         "hashtags":[],
         "urls":[],
         "user_mentions":[]
         }
         */
        //		BOOL doesContainURL = [tweet.text rangeOfString:@"http"].location != NSNotFound;
        //		tweet.containsURL = [NSNumber numberWithBool:doesContainURL];
        
		tweet.date = [[tweet createdAtDateFormatter] dateFromString:[d objectForKey:@"created_at"]];
		tweet.user = user;
	}
	tweet.isFavorite = [d objectForKey:@"favorited"];
    
    if(tweet.isFavorite) {
        NSLog(@"-- %@", tweet.text);
        NSLog(@"-- %@", d);
    }
    
	NSLog(@"** created %d favorite %@ %@ %@ %@", wasCreated, tweet.isFavorite, tweet.uid, tweet.user.screenName, tweet.text);
	
	return tweet;
}

+ (NSArray *)saveTweetsFromDictionariesArray:(NSArray *)a {
	// TODO: remove non-favorites between new favorites bounds
    
    NSManagedObjectContext *parentContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = parentContext;
    
    __block BOOL success = NO;
    __block NSError *error = nil;
    
    __weak NSMutableArray *tweets = [NSMutableArray array];
    
	[parentContext performBlockAndWait:^{
        for(NSDictionary *d in a) {
            THTweet *t = [THTweet updateOrCreateTweetFromDictionary:d context:privateContext];
            if(t) [tweets addObject:t];
        }
        
        success = [privateContext save:&error];
    }];
    
    if(success == NO) {
        NSLog(@"-- save error: %@", [error localizedDescription]);
        return nil;
    }
    
	return tweets;
}

- (NSAttributedString *)attributedString {
    
//    NSLog(@"-- attributedString");
    
    NSString *statusString = self.text;
    
	NSMutableAttributedString *attributedStatusString = [[NSMutableAttributedString alloc] initWithString:statusString];
    
	// Defining our paragraph style for the tweet text. Starting with the shadow to make the text
	// appear inset against the gray background.
	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:.8]];
	[textShadow setShadowBlurRadius:0];
	[textShadow setShadowOffset:NSMakeSize(0, -1)];
    
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//	[paragraphStyle setMinimumLineHeight:22];
//	[paragraphStyle setMaximumLineHeight:22];
//	[paragraphStyle setParagraphSpacing:0];
//	[paragraphStyle setParagraphSpacingBefore:0];
//	[paragraphStyle setTighteningFactorForTruncation:4];
	[paragraphStyle setAlignment:NSNaturalTextAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
	
	// Our initial set of attributes that are applied to the full string length
	NSDictionary *fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor colorWithDeviceHue:.53 saturation:.13 brightness:.26 alpha:1], NSForegroundColorAttributeName,
									textShadow, NSShadowAttributeName,
									//[NSCursor arrowCursor], NSCursorAttributeName,
									[NSNumber numberWithFloat:0.0], NSKernAttributeName,
									[NSNumber numberWithInt:0], NSLigatureAttributeName,
									paragraphStyle, NSParagraphStyleAttributeName,
									[NSFont systemFontOfSize:11.0], NSFontAttributeName, nil];
	[attributedStatusString addAttributes:fullAttributes range:NSMakeRange(0, [statusString length])];
    
	// Generate arrays of our interesting items. Links, usernames, hashtags.
    
	NSArray *linkMatches = [[self linksRegex] matchesInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
	NSArray *usernameMatches = [[self usernamesRegex] matchesInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
	NSArray *hashtagMatches = [[self hashtagsRegex] matchesInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
	
	// Iterate across the string matches from our regular expressions, find the range
	// of each match, add new attributes to that range
	for (NSTextCheckingResult *linkMatch in linkMatches) {
		NSRange range = [linkMatch range];
        NSString *s = [statusString substringWithRange:range];
		if( range.location != NSNotFound ) {
			// Add custom attribute of LinkMatch to indicate where our URLs are found. Could be blue
			// or any other color.
			NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
									  [NSCursor pointingHandCursor], NSCursorAttributeName,
									  [NSColor blueColor], NSForegroundColorAttributeName,
									  [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
									  s, @"LinkMatch",
									  nil];
			[attributedStatusString addAttributes:linkAttr range:range];
		}
	}
	
	for (NSTextCheckingResult *usernameMatch in usernameMatches) {
		NSRange range = [usernameMatch range];
        NSString *s = [statusString substringWithRange:range];
		if( range.location != NSNotFound ) {
			// Add custom attribute of UsernameMatch to indicate where our usernames are found
			NSDictionary *linkAttr2 = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSColor blackColor], NSForegroundColorAttributeName,
									   [NSCursor pointingHandCursor], NSCursorAttributeName,
									   [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
									   s, @"UsernameMatch",
									   nil];
			[attributedStatusString addAttributes:linkAttr2 range:range];
		}
	}
	
	for (NSTextCheckingResult *hashtagMatch in hashtagMatches) {
		NSRange range = [hashtagMatch range];
        NSString *s = [statusString substringWithRange:range];
		if( range.location != NSNotFound ) {
			// Add custom attribute of HashtagMatch to indicate where our hashtags are found
			NSDictionary *linkAttr3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSColor grayColor], NSForegroundColorAttributeName,
                                       [NSCursor pointingHandCursor], NSCursorAttributeName,
                                       [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                       s, @"HashtagMatch",
                                       nil];
			[attributedStatusString addAttributes:linkAttr3 range:range];
		}
	}
	
    return attributedStatusString;
    
    
    
    
    
    
    
    
    
//	[_tweetTextTextView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
//	[_tweetTextTextView setBackgroundColor:[NSColor clearColor]];
//	[_tweetTextTextView setTextContainerInset:NSZeroSize];
//	[[_tweetTextTextView textStorage] setAttributedString:attributedStatusString];
//	[_tweetTextTextView setEditable:NO];
//	[_tweetTextTextView setSelectable:YES];
//    
//    [attributedStatusString release];
}

#pragma mark -
#pragma mark regex

- (NSRegularExpression *)linksRegex {
    if(linksRegex == nil) {
        NSString *pattern = @"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))";
        linksRegex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    return linksRegex;
}

- (NSRegularExpression *)usernamesRegex {
    if(usernamesRegex == nil) {
        NSString *pattern = @"@{1}([-A-Za-z0-9_]{2,})";
        usernamesRegex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    return usernamesRegex;
}

- (NSRegularExpression *)hashtagsRegex {
    if(hashtagsRegex == nil) {
        NSString *pattern = @"[\\s]{1,}#{1}([^\\s]{2,})";
        hashtagsRegex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    return hashtagsRegex;
}

@end


