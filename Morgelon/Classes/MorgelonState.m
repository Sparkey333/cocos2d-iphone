//
// MorgelonState.m
//

#import "MorgelonTypes.h"

@implementation MorgelonState

+ (instancetype)sharedState
{
	static MorgelonState *state = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		state = [[MorgelonState alloc] init];
		[state reset];
	});
	return state;
}

- (void)reset
{
	self.threads = 3;
	self.evidence = 0;
	self.denial = 0;
	self.bloom = 12;
	self.power = 0;
	self.dismissedByClinic = NO;
	self.vaccineUnknown = YES;
	self.lastLie = @"There is nothing in your skin.";
}

- (void)pullThread
{
	if (self.threads <= 0) {
		self.threads = 1;
	}
	self.threads += 1;
	self.bloom = MIN(100, self.bloom + 7);
	self.evidence += 1;
	self.power += 1;
}

- (void)recordEvidence:(NSString *)fragment
{
	self.evidence += 1;
	self.power += 1;
	if (fragment.length) {
		self.lastLie = fragment;
	}
}

- (void)receiveDenial
{
	self.denial += 1;
	self.dismissedByClinic = YES;
	// Denial feeds the bloom — what is refused grows roots.
	self.bloom = MIN(100, self.bloom + 5);
}

- (void)floodZone
{
	self.denial += 2;
	self.bloom = MIN(100, self.bloom + 9);
	self.evidence += 1;
	self.lastLie = @"The zone was never contaminated.";
}

- (BOOL)hasAscended
{
	// The appearance of mischief is evidence enough with power.
	return (self.evidence >= 4 && self.power >= 5) || self.bloom >= 80;
}

@end
