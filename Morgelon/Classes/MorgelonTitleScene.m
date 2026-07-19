#import "MorgelonTitleScene.h"
#import "MorgelonClinicScene.h"
#import "MorgelonTypes.h"
#import "cocos2d-ui.h"

@implementation MorgelonTitleScene

+ (CCScene *)scene
{
	CCScene *scene = [CCScene node];
	[scene addChild:[self node]];
	return scene;
}

- (id)init
{
	if ((self = [super init])) {
		[[MorgelonState sharedState] reset];

		CGSize s = [CCDirector sharedDirector].viewSize;
		CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.05 green:0.07 blue:0.06 alpha:1]];
		[self addChild:bg];

		CCLabelTTF *brand = [CCLabelTTF labelWithString:@"MORGELON"
											   fontName:@"HelveticaNeue-Light"
											   fontSize:42];
		brand.color = [CCColor colorWithRed:0.92 green:0.93 blue:0.88 alpha:1];
		brand.position = ccp(s.width * 0.5f, s.height * 0.62f);
		[self addChild:brand];

		CCLabelTTF *line = [CCLabelTTF labelWithString:@"Threads come out everywhere.\nDoctors call you crazy. Leave."
											  fontName:@"HelveticaNeue"
											  fontSize:14];
		line.color = [CCColor colorWithRed:0.62 green:0.72 blue:0.58 alpha:1];
		line.position = ccp(s.width * 0.5f, s.height * 0.48f);
		[self addChild:line];

		CCButton *enter = [CCButton buttonWithTitle:@"ENTER THE CLINIC"];
		enter.position = ccp(s.width * 0.5f, s.height * 0.28f);
		[enter setTarget:self selector:@selector(enterClinic:)];
		[self addChild:enter];
	}
	return self;
}

- (void)enterClinic:(id)sender
{
	[[CCDirector sharedDirector] replaceScene:[MorgelonClinicScene scene]
							   withTransition:[CCTransition transitionFadeWithDuration:0.8f]];
}

@end
