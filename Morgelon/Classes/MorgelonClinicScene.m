#import "MorgelonClinicScene.h"
#import "MorgelonBodyScene.h"
#import "MorgelonTypes.h"
#import "cocos2d-ui.h"

@implementation MorgelonClinicScene {
	CCLabelTTF *_dialogue;
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
		CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.86 green:0.88 blue:0.90 alpha:1]];
		[self addChild:bg];

		CCLabelTTF *title = [CCLabelTTF labelWithString:@"CLINIC — ROOM 4"
											   fontName:@"HelveticaNeue-Medium"
											   fontSize:18];
		title.color = [CCColor colorWithRed:0.15 green:0.18 blue:0.20 alpha:1];
		title.position = ccp(s.width * 0.5f, s.height * 0.88f);
		[self addChild:title];

		_dialogue = [CCLabelTTF labelWithString:@"We see the marks you made yourself.\nThere are no fibers. Please leave."
									   fontName:@"HelveticaNeue"
									   fontSize:14];
		_dialogue.color = [CCColor colorWithRed:0.2 green:0.22 blue:0.25 alpha:1];
		_dialogue.position = ccp(s.width * 0.5f, s.height * 0.58f);
		[self addChild:_dialogue];

		CCButton *insist = [CCButton buttonWithTitle:@"Show them a thread"];
		insist.position = ccp(s.width * 0.5f, s.height * 0.34f);
		[insist setTarget:self selector:@selector(insist:)];
		[self addChild:insist];

		CCButton *leave = [CCButton buttonWithTitle:@"Leave (they already decided)"];
		leave.position = ccp(s.width * 0.5f, s.height * 0.22f);
		[leave setTarget:self selector:@selector(leave:)];
		[self addChild:leave];
	}
	return self;
}

- (void)insist:(id)sender
{
	[[MorgelonState sharedState] receiveDenial];
	[[MorgelonState sharedState] recordEvidence:@"Sample discarded before lab intake."];
	_dialogue.string = @"Security will walk you out.\nYour file says: delusional parasitosis.";
}

- (void)leave:(id)sender
{
	[[MorgelonState sharedState] receiveDenial];
	[[CCDirector sharedDirector] replaceScene:[MorgelonBodyScene scene]
							   withTransition:[CCTransition transitionFadeWithDuration:0.7f]];
}

@end
