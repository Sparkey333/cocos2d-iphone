#import "MorgelonFloodScene.h"
#import "MorgelonAspenScene.h"
#import "MorgelonTypes.h"
#import "cocos2d-ui.h"

@implementation MorgelonFloodScene {
	CCLabelTTF *_copy;
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
		CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.04 green:0.12 blue:0.14 alpha:1]];
		[self addChild:bg];

		CCLabelTTF *title = [CCLabelTTF labelWithString:@"FLOODED ZONES"
											   fontName:@"HelveticaNeue-Light"
											   fontSize:26];
		title.color = [CCColor colorWithRed:0.7 green:0.9 blue:0.88 alpha:1];
		title.position = ccp(s.width * 0.5f, s.height * 0.86f);
		[self addChild:title];

		_copy = [CCLabelTTF labelWithString:@"Sirens. Plastic sheeting. A press release\nalready writing you out of the water."
								  fontName:@"HelveticaNeue"
								  fontSize:13];
		_copy.color = [CCColor colorWithRed:0.55 green:0.75 blue:0.72 alpha:1];
		_copy.position = ccp(s.width * 0.5f, s.height * 0.62f);
		[self addChild:_copy];

		CCButton *wade = [CCButton buttonWithTitle:@"Wade deeper"];
		wade.position = ccp(s.width * 0.5f, s.height * 0.38f);
		[wade setTarget:self selector:@selector(wade:)];
		[self addChild:wade];

		CCButton *ask = [CCButton buttonWithTitle:@"Ask about the vaccine"];
		ask.position = ccp(s.width * 0.5f, s.height * 0.26f);
		[ask setTarget:self selector:@selector(askVaccine:)];
		[self addChild:ask];

		CCButton *vein = [CCButton buttonWithTitle:@"Follow the aspen into the blood"];
		vein.position = ccp(s.width * 0.5f, s.height * 0.14f);
		[vein setTarget:self selector:@selector(enterVein:)];
		[self addChild:vein];
	}
	return self;
}

- (void)wade:(id)sender
{
	[[MorgelonState sharedState] floodZone];
	_copy.string = @"Lies rise faster than water.\nYour name is already a rumor with a quarantine stamp.";
}

- (void)askVaccine:(id)sender
{
	MorgelonState *st = [MorgelonState sharedState];
	st.vaccineUnknown = YES;
	[st recordEvidence:@"Batch codes blacked out. No one knows."];
	_copy.string = @"Vaccine?? No one knows.\nThe clipboard smiles without answering.";
}

- (void)enterVein:(id)sender
{
	[[CCDirector sharedDirector] replaceScene:[MorgelonAspenScene scene]
							   withTransition:[CCTransition transitionFadeWithDuration:1.0f]];
}

@end
