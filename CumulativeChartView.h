//
//  CumulativeChartView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_COUNT 100

@protocol CumulativeChartViewDelegate
- (void)didSlideToScore:(NSUInteger)aScore;
- (void)didStopSlidingOnScore:(NSUInteger)aScore;
@end

@protocol CumulativeChartViewDataSource
- (NSUInteger)numberOfTweets;
- (NSUInteger)cumulatedTweetsForScore:(NSUInteger)aScore;
@end

@interface CumulativeChartView : NSView {
	NSUInteger score;
	
	IBOutlet NSObject <CumulativeChartViewDelegate> *delegate;
	IBOutlet NSObject <CumulativeChartViewDataSource> *dataSource;
	
	NSTrackingRectTag tag;
}

@property (nonatomic, retain) NSObject <CumulativeChartViewDelegate> *delegate;
@property (nonatomic, retain) NSObject <CumulativeChartViewDataSource> *dataSource;

- (void)setScore:(NSUInteger)aScore;
//- (void)sendValuesToDelegate;

@end