//
//  THController.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "THCumulativeChartView.h"
#import "THLocationVC.h"

#pragma mark FIXME: favorites syncronisation

#define MAX_COUNT 100

@class STTwitterAPIWrapper;
@class THTweet;
@class THTweetLocation;
@class THLocationPanel;
@class THLocationVC;
@class THCumulativeChartView;

@interface THController : NSObject <CumulativeChartViewDelegate, CumulativeChartViewDataSource, THLocationVCProtocol> {
	NSUInteger tweetsCount;
	NSUInteger numberOfTweetsForScore[MAX_COUNT+1];
	NSUInteger cumulatedTweetsForScore[MAX_COUNT+1];
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSArrayController *tweetArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *userArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *keywordArrayController;
@property (nonatomic, retain) IBOutlet NSPanel *locationPanel;
@property (nonatomic, retain) IBOutlet NSCollectionView *collectionView;
@property (nonatomic, retain) IBOutlet NSPanel *preferences;
@property (nonatomic, retain) IBOutlet THCumulativeChartView *cumulativeChartView;
@property (nonatomic, retain) IBOutlet NSTextField *expectedNbTweetsLabel;
@property (nonatomic, retain) IBOutlet NSTextField *expectedScoreLabel;

- (IBAction)update:(id)sender;
- (IBAction)synchronizeFavorites:(id)sender;
- (IBAction)chooseMedia:(id)sender;
- (IBAction)chooseLocation:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)updateCredentials:(id)sender;
- (IBAction)updateTweetScores:(id)sender;

- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAllAsUnread:(id)sender;

@end
