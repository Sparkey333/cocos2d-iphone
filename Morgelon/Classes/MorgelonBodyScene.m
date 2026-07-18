#import "MorgelonBodyScene.h"
#import "MorgelonFloodScene.h"
#import "MorgelonTypes.h"
#import "cocos2d-ui.h"

@implementation MorgelonBodyScene {
	CCLabelTTF *_status;
	CCLabelTTF *_threadLabel;
}

+ (CCScene *)scene
{
	CCScene *scene = [CCScene node];
	[scene addChild:[self node]];
	return scene;
}

- (id)init
{
	if ((self = [super init])) {
		CGSize s = [CCDirector sharedDirector].viewSize;
		CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.09 green:0.06 blue:0.07 alpha:1]];
		[self addChild:bg];

		CCLabelTTF *title = [CCLabelTTF labelWithString:@"THE BODY"
											   fontName:@"HelveticaNeue-Light"
											   fontSize:28];
		title.color = [CCColor colorWithRed:0.95 green:0.9 blue:0.88 alpha:1];
		title.position = ccp(s.width * 0.5f, s.height * 0.88f);
		[self addChild:title];

		_status = [CCLabelTTF labelWithString:@"Filaments under the nail. Tick-scar lattice.\nNeedles remembered as blessings. Voodoo as protocol."
									 fontName:@"HelveticaNeue"
									 fontSize:13];
		_status.color = [CCColor colorWithRed:0.7 green:0.55 blue:0.5 alpha:1];
		_status.position = ccp(s.width * 0.5f, s.height * 0.68f);
		[self addChild:_status];

		_threadLabel = [CCLabelTTF labelWithString:@"" fontName:@"HelveticaNeue" fontSize:14];
		_threadLabel.color = [CCColor colorWithRed:0.75 green:0.9 blue:0.55 alpha:1];
		_threadLabel.position = ccp(s.width * 0.5f, s.height * 0.48f);
		[self addChild:_threadLabel];
		[self refresh];

		CCButton *pull = [CCButton buttonWithTitle:@"Pull a thread"];
		pull.position = ccp(s.width * 0.5f, s.height * 0.32f);
		[pull setTarget:self selector:@selector(pullThread:)];
		[self addChild:pull];

		CCButton *zones = [CCButton buttonWithTitle:@"Enter the flooded zones"];
		zones.position = ccp(s.width * 0.5f, s.height * 0.20f);
		[zones setTarget:self selector:@selector(enterFlood:)];
		[self addChild:zones];
	}
	return self;
}

- (void)refresh
{
	MorgelonState *st = [MorgelonState sharedState];
	_threadLabel.string = [NSString stringWithFormat:@"Threads %ld · Bloom %ld%% · Evidence %ld · Power %ld",
						   (long)st.threads, (long)st.bloom, (long)st.evidence, (long)st.power];
}

- (void)pullThread:(id)sender
{
	[[MorgelonState sharedState] pullThread];
	[[MorgelonState sharedState] recordEvidence:@"Fiber matches no textile catalog."];
	_status.string = @"It comes out like fishing line from a living tree.\nAspen white. Still warm.";
	[self refresh];
}

- (void)enterFlood:(id)sender
{
	[[CCDirector sharedDirector] replaceScene:[MorgelonFloodScene scene]
							   withTransition:[CCTransition transitionFadeWithDuration:0.9f]];
}

@end
