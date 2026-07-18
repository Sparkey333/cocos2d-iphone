#import "MorgelonAspenScene.h"
#import "MorgelonTitleScene.h"
#import "MorgelonTypes.h"
#import "cocos2d-ui.h"

@implementation MorgelonAspenScene

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
		CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.12 green:0.03 blue:0.04 alpha:1]];
		[self addChild:bg];

		MorgelonState *st = [MorgelonState sharedState];
		BOOL ascended = [st hasAscended];

		CCLabelTTF *title = [CCLabelTTF labelWithString:@"ASPEN / BLOOD"
											   fontName:@"HelveticaNeue-Light"
											   fontSize:28];
		title.color = [CCColor colorWithRed:0.96 green:0.94 blue:0.9 alpha:1];
		title.position = ccp(s.width * 0.5f, s.height * 0.82f);
		[self addChild:title];

		NSString *body = ascended
			? @"Trees grow — like aspens — in your blood.\nThe filaments are a forest with a pulse.\n\nThey called you crazy.\nThe appearance of mischief is evidence enough with power."
			: @"Roots tap the marrow. Pale trunks behind the eyes.\nYou still need more thread, more zone, more proof\nbefore the mischief hardens into power.";

		CCLabelTTF *copy = [CCLabelTTF labelWithString:body
											  fontName:@"HelveticaNeue"
											  fontSize:13];
		copy.color = [CCColor colorWithRed:0.85 green:0.65 blue:0.55 alpha:1];
		copy.position = ccp(s.width * 0.5f, s.height * 0.52f);
		[self addChild:copy];

		NSString *stats = [NSString stringWithFormat:@"Bloom %ld%% · Evidence %ld · Denial %ld · Power %ld",
						   (long)st.bloom, (long)st.evidence, (long)st.denial, (long)st.power];
		CCLabelTTF *meter = [CCLabelTTF labelWithString:stats fontName:@"HelveticaNeue" fontSize:12];
		meter.color = [CCColor colorWithRed:0.6 green:0.85 blue:0.45 alpha:1];
		meter.position = ccp(s.width * 0.5f, s.height * 0.28f);
		[self addChild:meter];

		CCButton *again = [CCButton buttonWithTitle:ascended ? @"Begin again" : @"Return to the body"];
		again.position = ccp(s.width * 0.5f, s.height * 0.14f);
		[again setTarget:self selector:@selector(restart:)];
		[self addChild:again];
	}
	return self;
}

- (void)restart:(id)sender
{
	[[MorgelonState sharedState] reset];
	[[CCDirector sharedDirector] replaceScene:[MorgelonTitleScene scene]
							   withTransition:[CCTransition transitionFadeWithDuration:0.8f]];
}

@end
