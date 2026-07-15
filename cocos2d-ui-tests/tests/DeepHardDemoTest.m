//
//  DeepHardDemoTest.m
//  cocos2d-ui-tests
//
//  Deep, hard showcase starring Grossini's sister.
//  Exercises touch/mouse input, actions/easing, particles, animation,
//  escalating waves, scoring, dash, and combo systems.
//

#import "TestBase.h"
#import "CCParticles.h"

#if __CC_PLATFORM_MAC
#import "NSEvent+CC.h"
#endif

#pragma mark - Helpers

static inline CGFloat DHRandomFloat(CGFloat minValue, CGFloat maxValue)
{
	return minValue + ((CGFloat)arc4random() / (CGFloat)UINT32_MAX) * (maxValue - minValue);
}

static inline CGPoint DHRandomEdgePoint(CGSize size, CGFloat margin)
{
	NSInteger edge = arc4random_uniform(4);
	switch (edge) {
		case 0: return ccp(DHRandomFloat(margin, size.width - margin), size.height + margin);
		case 1: return ccp(DHRandomFloat(margin, size.width - margin), -margin);
		case 2: return ccp(-margin, DHRandomFloat(margin, size.height - margin));
		default: return ccp(size.width + margin, DHRandomFloat(margin, size.height - margin));
	}
}

typedef NS_ENUM(NSInteger, DHEnemyKind) {
	DHEnemyKindChaser = 0,
	DHEnemyKindOrbiter,
	DHEnemyKindDasher,
	DHEnemyKindBomber,
};

#pragma mark - Arena

@interface DeepHardArena : CCNode
@end

@implementation DeepHardArena
{
	CCSprite *_hero;
	CCParticleSystem *_heroAura;
	CCLabelTTF *_hudLabel;
	CCLabelTTF *_waveLabel;
	CCLabelTTF *_bannerLabel;

	NSMutableArray *_enemies;
	NSMutableArray *_projectiles;
	NSMutableArray *_pickups;

	CGPoint _moveTarget;
	BOOL _pointerDown;
	BOOL _alive;
	BOOL _nightmare;

	CGFloat _health;
	CGFloat _maxHealth;
	CGFloat _dashCooldown;
	CGFloat _invuln;
	CGFloat _spawnTimer;
	CGFloat _waveTimer;
	CGFloat _elapsed;

	NSInteger _score;
	NSInteger _combo;
	NSInteger _bestCombo;
	NSInteger _wave;
	NSInteger _kills;
}

- (instancetype)initWithNightmare:(BOOL)nightmare
{
	self = [super init];
	if (!self) return nil;

	_nightmare = nightmare;
	_enemies = [NSMutableArray array];
	_projectiles = [NSMutableArray array];
	_pickups = [NSMutableArray array];

	self.userInteractionEnabled = YES;
	self.multipleTouchEnabled = NO;
	self.claimsUserInteraction = YES;
	self.contentSizeType = CCSizeTypeNormalized;
	self.contentSize = CGSizeMake(1, 1);

	_maxHealth = nightmare ? 3.0f : 5.0f;
	_health = _maxHealth;
	_alive = YES;
	_wave = 1;
	_spawnTimer = 0.6f;
	_waveTimer = nightmare ? 12.0f : 16.0f;

	[self buildBackdrop];
	[self buildHero];
	[self buildHUD];
	[self flashBanner:_nightmare ? @"NIGHTMARE — SURVIVE" : @"DEEP HARD — SURVIVE" duration:1.6f];

	return self;
}

- (void)onEnter
{
	[super onEnter];
	CGSize size = self.contentSizeInPoints;
	_moveTarget = ccp(size.width * 0.5f, size.height * 0.42f);
	_hero.position = _moveTarget;
}

#pragma mark Setup

- (void)buildBackdrop
{
	CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.06f green:0.07f blue:0.12f alpha:1]];
	bg.contentSizeType = CCSizeTypeNormalized;
	bg.contentSize = CGSizeMake(1, 1);
	[self addChild:bg z:-20];

	for (NSInteger i = 0; i < 18; i++) {
		CCSprite *star = [CCSprite spriteWithImageNamed:@"Sprites/circle.png"];
		star.scale = DHRandomFloat(0.04f, 0.12f);
		star.opacity = DHRandomFloat(0.15f, 0.45f);
		star.color = [CCColor colorWithRed:0.55f green:0.75f blue:1.0f alpha:1];
		star.positionType = CCPositionTypeNormalized;
		star.position = ccp(DHRandomFloat(0, 1), DHRandomFloat(0, 1));
		[self addChild:star z:-10];

		CCAction *pulse = [CCActionSequence actions:
			[CCActionEaseSineInOut actionWithAction:[CCActionFadeTo actionWithDuration:DHRandomFloat(0.8f, 1.8f) opacity:DHRandomFloat(0.05f, 0.2f)]],
			[CCActionEaseSineInOut actionWithAction:[CCActionFadeTo actionWithDuration:DHRandomFloat(0.8f, 1.8f) opacity:star.opacity]],
			nil];
		[star runAction:[CCActionRepeatForever actionWithAction:pulse]];
	}

	CCSprite *floor = [CCSprite spriteWithImageNamed:@"gridBackground.png"];
	floor.positionType = CCPositionTypeNormalized;
	floor.position = ccp(0.5f, 0.5f);
	floor.opacity = 0.18f;
	floor.scale = 1.35f;
	[self addChild:floor z:-9];
}

- (void)buildHero
{
	_hero = [CCSprite spriteWithImageNamed:@"Sprites/grossinis_sister.png"];
	_hero.scale = 0.55f;
	[self addChild:_hero z:20];

	[_hero runAction:[CCActionRepeatForever actionWithAction:[CCActionSequence actions:
		[CCActionEaseSineInOut actionWithAction:[CCActionScaleTo actionWithDuration:0.45f scale:0.58f]],
		[CCActionEaseSineInOut actionWithAction:[CCActionScaleTo actionWithDuration:0.45f scale:0.52f]],
		nil]]];

	_heroAura = [CCParticleFlower node];
	_heroAura.scale = 0.35f;
	_heroAura.emissionRate = 18;
	_heroAura.totalParticles = 40;
	_heroAura.position = CGPointZero;
	[_hero addChild:_heroAura z:-1];
}

- (void)buildHUD
{
	_hudLabel = [CCLabelTTF labelWithString:@"" fontName:@"HelveticaNeue-Medium" fontSize:13];
	_hudLabel.positionType = CCPositionTypeMake(CCPositionUnitNormalized, CCPositionUnitUIPoints, CCPositionReferenceCornerTopLeft);
	_hudLabel.anchorPoint = ccp(0, 1);
	_hudLabel.position = ccp(0.02f, 78);
	_hudLabel.horizontalAlignment = CCTextAlignmentLeft;
	_hudLabel.color = [CCColor colorWithRed:0.92f green:0.95f blue:1.0f alpha:1];
	[self addChild:_hudLabel z:100];

	_waveLabel = [CCLabelTTF labelWithString:@"" fontName:@"HelveticaNeue-Bold" fontSize:15];
	_waveLabel.positionType = CCPositionTypeMake(CCPositionUnitNormalized, CCPositionUnitUIPoints, CCPositionReferenceCornerTopRight);
	_waveLabel.anchorPoint = ccp(1, 1);
	_waveLabel.position = ccp(0.98f, 78);
	_waveLabel.color = [CCColor colorWithRed:1.0f green:0.72f blue:0.35f alpha:1];
	[self addChild:_waveLabel z:100];

	_bannerLabel = [CCLabelTTF labelWithString:@"" fontName:@"HelveticaNeue-Bold" fontSize:22];
	_bannerLabel.positionType = CCPositionTypeNormalized;
	_bannerLabel.position = ccp(0.5f, 0.72f);
	_bannerLabel.opacity = 0;
	_bannerLabel.color = [CCColor colorWithRed:1 green:0.9f blue:0.55f alpha:1];
	[self addChild:_bannerLabel z:110];
}

#pragma mark Update loop

- (void)update:(CCTime)delta
{
	[self refreshHUD];
	if (!_alive) return;

	_elapsed += delta;
	_dashCooldown = MAX(0, _dashCooldown - delta);
	_invuln = MAX(0, _invuln - delta);
	_waveTimer -= delta;
	_spawnTimer -= delta;

	[self moveHero:delta];
	[self updateEnemies:delta];
	[self updateProjectiles:delta];
	[self updatePickups:delta];
	[self resolveCollisions];

	if (_spawnTimer <= 0) {
		[self spawnWavePack];
		CGFloat pace = _nightmare ? 0.55f : 0.85f;
		_spawnTimer = MAX(0.22f, pace - (_wave * 0.035f));
	}

	if (_waveTimer <= 0) {
		_wave += 1;
		_waveTimer = _nightmare ? 10.0f : 14.0f;
		[self flashBanner:[NSString stringWithFormat:@"WAVE %ld — HARDER", (long)_wave] duration:1.1f];
		[self burstRingAt:_hero.position color:[CCColor colorWithRed:1 green:0.7f blue:0.2f alpha:1]];
		if (_wave % 3 == 0) {
			[self spawnBoss];
		}
	}
}

- (void)refreshHUD
{
	_hudLabel.string = [NSString stringWithFormat:
		@"HP %.0f/%.0f   SCORE %ld   COMBO x%ld (best %ld)\nKILLS %ld   DASH %@",
		_health, _maxHealth, (long)_score, (long)MAX(_combo, 1), (long)_bestCombo, (long)_kills,
		_dashCooldown > 0 ? [NSString stringWithFormat:@"%.1fs", _dashCooldown] : @"READY (double-tap / right-click)"];
	_waveLabel.string = [NSString stringWithFormat:@"WAVE %ld\n%.0fs", (long)_wave, MAX(0, _waveTimer)];
}

- (void)moveHero:(CCTime)delta
{
	CGPoint pos = _hero.position;
	CGPoint deltaPos = ccpSub(_moveTarget, pos);
	CGFloat dist = ccpLength(deltaPos);
	CGFloat speed = _nightmare ? 420.0f : 360.0f;
	if (dist > 1.0f) {
		CGPoint step = ccpMult(ccpNormalize(deltaPos), MIN(dist, speed * delta));
		pos = ccpAdd(pos, step);
	}

	CGSize size = self.contentSizeInPoints;
	CGFloat pad = 28.0f;
	pos.x = clampf(pos.x, pad, size.width - pad);
	pos.y = clampf(pos.y, pad, size.height - pad);
	_hero.position = pos;

	if (dist > 8.0f) {
		CGFloat angle = -CC_RADIANS_TO_DEGREES(ccpToAngle(deltaPos));
		_hero.rotation = _hero.rotation + (angle - _hero.rotation) * MIN(1.0f, 10.0f * delta);
	}
}

#pragma mark Spawning

- (void)spawnWavePack
{
	NSInteger count = 1 + (_wave / 2) + (_nightmare ? 1 : 0);
	count = MIN(count, _nightmare ? 7 : 5);
	for (NSInteger i = 0; i < count; i++) {
		DHEnemyKind kind = (DHEnemyKind)arc4random_uniform(4);
		if (_wave < 2 && kind == DHEnemyKindBomber) kind = DHEnemyKindChaser;
		[self spawnEnemy:kind];
	}
}

- (void)spawnEnemy:(DHEnemyKind)kind
{
	CGSize size = self.contentSizeInPoints;
	NSString *image = @"Sprites/shape-0.png";
	CCColor *tint = [CCColor colorWithRed:1 green:0.35f blue:0.35f alpha:1];
	CGFloat scale = 0.55f;
	CGFloat hp = 1.0f;
	CGFloat speed = 90.0f + _wave * 8.0f;

	switch (kind) {
		case DHEnemyKindChaser:
			image = @"Sprites/shape-0.png";
			tint = [CCColor colorWithRed:1 green:0.3f blue:0.3f alpha:1];
			scale = 0.5f;
			hp = 1;
			speed = 110 + _wave * 10;
			break;
		case DHEnemyKindOrbiter:
			image = @"Sprites/shape-2.png";
			tint = [CCColor colorWithRed:0.45f green:0.75f blue:1 alpha:1];
			scale = 0.48f;
			hp = 1;
			speed = 80 + _wave * 7;
			break;
		case DHEnemyKindDasher:
			image = @"Sprites/shape-1.png";
			tint = [CCColor colorWithRed:1 green:0.85f blue:0.25f alpha:1];
			scale = 0.52f;
			hp = 1;
			speed = 160 + _wave * 12;
			break;
		case DHEnemyKindBomber:
			image = @"Sprites/shape-3.png";
			tint = [CCColor colorWithRed:0.85f green:0.35f blue:1 alpha:1];
			scale = 0.6f;
			hp = 2;
			speed = 70 + _wave * 5;
			break;
	}

	CCSprite *enemy = [CCSprite spriteWithImageNamed:image];
	enemy.scale = scale;
	enemy.color = tint;
	enemy.position = DHRandomEdgePoint(size, 40);
	enemy.userObject = @{
		@"kind": @(kind),
		@"hp": @(hp),
		@"speed": @(speed),
		@"age": @(0),
		@"cooldown": @(DHRandomFloat(0.4f, 1.2f)),
	};
	[self addChild:enemy z:10];
	[_enemies addObject:enemy];

	enemy.opacity = 0;
	[enemy runAction:[CCActionFadeIn actionWithDuration:0.18f]];
	[enemy runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:1.2f angle:(_nightmare ? 220 : 140)]]];
}

- (void)spawnBoss
{
	CGSize size = self.contentSizeInPoints;
	CCSprite *boss = [CCSprite spriteWithImageNamed:@"Sprites/grossini.png"];
	boss.scale = 0.7f;
	boss.color = [CCColor colorWithRed:1 green:0.2f blue:0.55f alpha:1];
	boss.position = ccp(size.width * 0.5f, size.height + 60);
	boss.userObject = @{
		@"kind": @(DHEnemyKindBomber),
		@"hp": @(_nightmare ? 14 : 10),
		@"speed": @(70.0f + _wave * 3.0f),
		@"age": @(0),
		@"cooldown": @(0.35f),
		@"boss": @YES,
	};
	[self addChild:boss z:15];
	[_enemies addObject:boss];

	[boss runAction:[CCActionEaseBackOut actionWithAction:[CCActionMoveTo actionWithDuration:0.7f position:ccp(size.width * 0.5f, size.height * 0.78f)]]];
	[self flashBanner:@"BOSS INCOMING" duration:1.2f];

	NSMutableArray *frames = [NSMutableArray array];
	for (NSInteger i = 1; i <= 14; i++) {
		NSString *name = [NSString stringWithFormat:@"Images/grossini_dance_%02ld.png", (long)i];
		CCSpriteFrame *frame = [CCSpriteFrame frameWithImageNamed:name];
		if (frame) [frames addObject:frame];
	}
	if (frames.count > 0) {
		CCAnimation *anim = [CCAnimation animationWithSpriteFrames:frames delay:0.06f];
		[boss runAction:[CCActionRepeatForever actionWithAction:[CCActionAnimate actionWithAnimation:anim]]];
	}
}

#pragma mark Combat systems

- (void)updateEnemies:(CCTime)delta
{
	CGPoint heroPos = _hero.position;
	NSMutableArray *dead = [NSMutableArray array];

	for (CCSprite *enemy in _enemies) {
		NSDictionary *state = enemy.userObject;
		DHEnemyKind kind = [state[@"kind"] integerValue];
		CGFloat speed = [state[@"speed"] floatValue];
		CGFloat age = [state[@"age"] floatValue] + delta;
		CGFloat cooldown = [state[@"cooldown"] floatValue] - delta;
		BOOL isBoss = [state[@"boss"] boolValue];

		CGPoint toHero = ccpSub(heroPos, enemy.position);
		CGFloat dist = ccpLength(toHero);
		CGPoint dir = dist > 0.1f ? ccpNormalize(toHero) : ccp(1, 0);

		switch (kind) {
			case DHEnemyKindChaser:
				enemy.position = ccpAdd(enemy.position, ccpMult(dir, speed * delta));
				break;
			case DHEnemyKindOrbiter: {
				CGPoint tangent = ccp(-dir.y, dir.x);
				CGPoint move = ccpAdd(ccpMult(dir, speed * 0.35f * delta), ccpMult(tangent, speed * delta));
				enemy.position = ccpAdd(enemy.position, move);
				if (cooldown <= 0) {
					[self fireProjectileFrom:enemy.position toward:heroPos speed:180 + _wave * 8 damage:1 hostile:YES];
					cooldown = _nightmare ? 0.7f : 1.1f;
				}
				break;
			}
			case DHEnemyKindDasher:
				if (cooldown <= 0) {
					CGPoint dash = ccpMult(dir, (_nightmare ? 220 : 170));
					[enemy runAction:[CCActionEaseOut actionWithAction:[CCActionMoveBy actionWithDuration:0.22f position:dash] rate:2.0f]];
					cooldown = _nightmare ? 0.85f : 1.25f;
				} else {
					enemy.position = ccpAdd(enemy.position, ccpMult(dir, speed * 0.35f * delta));
				}
				break;
			case DHEnemyKindBomber:
				enemy.position = ccpAdd(enemy.position, ccpMult(dir, speed * delta));
				if (cooldown <= 0) {
					NSInteger shots = isBoss ? 10 : 6;
					for (NSInteger i = 0; i < shots; i++) {
						CGFloat ang = (M_PI * 2.0 * i) / shots + age;
						CGPoint aim = ccpAdd(enemy.position, ccp(cosf(ang) * 40, sinf(ang) * 40));
						[self fireProjectileFrom:enemy.position toward:aim speed:140 + _wave * 6 damage:1 hostile:YES];
					}
					cooldown = isBoss ? (_nightmare ? 0.55f : 0.8f) : (_nightmare ? 1.1f : 1.6f);
				}
				break;
		}

		enemy.userObject = @{
			@"kind": @(kind),
			@"hp": state[@"hp"],
			@"speed": @(speed),
			@"age": @(age),
			@"cooldown": @(cooldown),
			@"boss": @(isBoss),
		};

		if (enemy.position.x < -80 || enemy.position.x > self.contentSizeInPoints.width + 80 ||
			enemy.position.y < -80 || enemy.position.y > self.contentSizeInPoints.height + 80) {
			if (!isBoss) [dead addObject:enemy];
		}
	}

	for (CCSprite *enemy in dead) {
		[enemy removeFromParent];
		[_enemies removeObject:enemy];
	}
}

- (void)fireProjectileFrom:(CGPoint)origin toward:(CGPoint)target speed:(CGFloat)speed damage:(CGFloat)damage hostile:(BOOL)hostile
{
	CCSprite *bolt = [CCSprite spriteWithImageNamed:@"Sprites/circle.png"];
	bolt.scale = hostile ? 0.18f : 0.22f;
	bolt.color = hostile
		? [CCColor colorWithRed:1 green:0.4f blue:0.2f alpha:1]
		: [CCColor colorWithRed:0.35f green:1 blue:0.7f alpha:1];
	bolt.position = origin;
	CGPoint dir = ccpSub(target, origin);
	if (ccpLength(dir) < 0.1f) dir = ccp(0, 1);
	dir = ccpNormalize(dir);
	bolt.userObject = @{
		@"vel": [NSValue valueWithCGPoint:ccpMult(dir, speed)],
		@"damage": @(damage),
		@"hostile": @(hostile),
		@"life": @(2.8f),
	};
	[self addChild:bolt z:12];
	[_projectiles addObject:bolt];
}

- (void)updateProjectiles:(CCTime)delta
{
	NSMutableArray *dead = [NSMutableArray array];
	for (CCSprite *bolt in _projectiles) {
		NSDictionary *state = bolt.userObject;
		CGPoint vel = [state[@"vel"] CGPointValue];
		CGFloat life = [state[@"life"] floatValue] - delta;
		bolt.position = ccpAdd(bolt.position, ccpMult(vel, delta));
		if (life <= 0) {
			[dead addObject:bolt];
		} else {
			bolt.userObject = @{
				@"vel": state[@"vel"],
				@"damage": state[@"damage"],
				@"hostile": state[@"hostile"],
				@"life": @(life),
			};
		}
	}
	for (CCSprite *bolt in dead) {
		[bolt removeFromParent];
		[_projectiles removeObject:bolt];
	}
}

- (void)updatePickups:(CCTime)delta
{
	NSMutableArray *dead = [NSMutableArray array];
	for (CCSprite *pickup in _pickups) {
		CGFloat life = [pickup.userObject[@"life"] floatValue] - delta;
		if (life <= 0) {
			[dead addObject:pickup];
			continue;
		}
		pickup.userObject = @{@"life": @(life), @"kind": pickup.userObject[@"kind"]};
		if (ccpDistance(pickup.position, _hero.position) < 34) {
			NSString *kind = pickup.userObject[@"kind"];
			if ([kind isEqualToString:@"heal"]) {
				_health = MIN(_maxHealth, _health + 1);
				[self flashBanner:@"+1 HP" duration:0.6f];
			} else {
				_score += 250;
				_combo += 2;
				_dashCooldown = 0;
				[self flashBanner:@"OVERCLOCK" duration:0.7f];
				[self novaBlast];
			}
			[self burstRingAt:pickup.position color:[CCColor colorWithRed:0.4f green:1 blue:0.7f alpha:1]];
			[dead addObject:pickup];
		}
	}
	for (CCSprite *pickup in dead) {
		[pickup removeFromParent];
		[_pickups removeObject:pickup];
	}
}

- (void)resolveCollisions
{
	CGFloat heroRadius = 26.0f;

	NSMutableArray *deadEnemies = [NSMutableArray array];
	NSMutableArray *deadBolts = [NSMutableArray array];

	for (CCSprite *bolt in _projectiles) {
		BOOL hostile = [bolt.userObject[@"hostile"] boolValue];
		CGFloat damage = [bolt.userObject[@"damage"] floatValue];
		if (hostile) {
			if (_invuln <= 0 && ccpDistance(bolt.position, _hero.position) < heroRadius) {
				[self hurtHero:damage];
				[deadBolts addObject:bolt];
			}
		} else {
			for (CCSprite *enemy in _enemies) {
				CGFloat hitR = [enemy.userObject[@"boss"] boolValue] ? 40.0f : 28.0f;
				if (ccpDistance(bolt.position, enemy.position) < hitR) {
					[self damageEnemy:enemy amount:damage];
					[deadBolts addObject:bolt];
					if ([enemy.userObject[@"hp"] floatValue] <= 0) [deadEnemies addObject:enemy];
					break;
				}
			}
		}
	}

	if (_invuln <= 0) {
		for (CCSprite *enemy in _enemies) {
			CGFloat hitR = [enemy.userObject[@"boss"] boolValue] ? 42.0f : 30.0f;
			if (ccpDistance(enemy.position, _hero.position) < hitR) {
				[self hurtHero:1];
				[self damageEnemy:enemy amount:1];
				if ([enemy.userObject[@"hp"] floatValue] <= 0) [deadEnemies addObject:enemy];
			}
		}
	}

	for (CCSprite *bolt in deadBolts) {
		[bolt removeFromParent];
		[_projectiles removeObject:bolt];
	}
	for (CCSprite *enemy in deadEnemies) {
		[self killEnemy:enemy];
	}
}

- (void)damageEnemy:(CCSprite *)enemy amount:(CGFloat)amount
{
	NSDictionary *state = enemy.userObject;
	CGFloat hp = [state[@"hp"] floatValue] - amount;
	NSMutableDictionary *next = [state mutableCopy];
	next[@"hp"] = @(hp);
	enemy.userObject = next;

	[enemy runAction:[CCActionSequence actions:
		[CCActionTintTo actionWithDuration:0.05f color:[CCColor whiteColor]],
		[CCActionTintTo actionWithDuration:0.12f color:enemy.color],
		nil]];
	[enemy runAction:[CCActionSequence actions:
		[CCActionScaleTo actionWithDuration:0.05f scale:enemy.scale * 1.15f],
		[CCActionScaleTo actionWithDuration:0.1f scale:enemy.scale],
		nil]];
}

- (void)killEnemy:(CCSprite *)enemy
{
	BOOL boss = [enemy.userObject[@"boss"] boolValue];
	_kills += 1;
	_combo += 1;
	_bestCombo = MAX(_bestCombo, _combo);
	_score += (boss ? 1000 : 100) * MAX(_combo, 1);

	[self burstRingAt:enemy.position color:enemy.color];
	CCParticleExplosion *boom = [CCParticleExplosion node];
	boom.position = enemy.position;
	boom.scale = boss ? 0.7f : 0.35f;
	boom.autoRemoveOnFinish = YES;
	boom.duration = 0.12f;
	[self addChild:boom z:30];

	if (arc4random_uniform(100) < (boss ? 100 : 18)) {
		[self spawnPickupAt:enemy.position];
	}

	[enemy removeFromParent];
	[_enemies removeObject:enemy];

	if (boss) {
		[self flashBanner:@"BOSS DOWN" duration:1.0f];
		_health = MIN(_maxHealth, _health + 1);
	}
}

- (void)spawnPickupAt:(CGPoint)pos
{
	BOOL heal = arc4random_uniform(100) < 55;
	CCSprite *pickup = [CCSprite spriteWithImageNamed:heal ? @"Sprites/bird.png" : @"fire.png"];
	pickup.scale = 0.45f;
	pickup.position = pos;
	pickup.userObject = @{@"life": @(8.0f), @"kind": heal ? @"heal" : @"overclock"};
	[self addChild:pickup z:8];
	[_pickups addObject:pickup];
	[pickup runAction:[CCActionRepeatForever actionWithAction:[CCActionSequence actions:
		[CCActionEaseSineInOut actionWithAction:[CCActionMoveBy actionWithDuration:0.5f position:ccp(0, 8)]],
		[CCActionEaseSineInOut actionWithAction:[CCActionMoveBy actionWithDuration:0.5f position:ccp(0, -8)]],
		nil]]];
}

- (void)hurtHero:(CGFloat)amount
{
	if (!_alive || _invuln > 0) return;
	_health -= amount;
	_combo = 0;
	_invuln = 0.85f;

	[_hero runAction:[CCActionSequence actions:
		[CCActionBlink actionWithDuration:0.85f blinks:6],
		nil]];
	[self burstRingAt:_hero.position color:[CCColor colorWithRed:1 green:0.2f blue:0.2f alpha:1]];

	if (_health <= 0) {
		_health = 0;
		[self gameOver];
	}
}

- (void)gameOver
{
	_alive = NO;
	_heroAura.emissionRate = 0;
	[_hero runAction:[CCActionSpawn actions:
		[CCActionEaseBackIn actionWithAction:[CCActionScaleTo actionWithDuration:0.45f scale:0.05f]],
		[CCActionFadeOut actionWithDuration:0.45f],
		nil]];

	CCParticleExplosion *boom = [CCParticleExplosion node];
	boom.position = _hero.position;
	boom.autoRemoveOnFinish = YES;
	[self addChild:boom z:40];

	[self flashBanner:[NSString stringWithFormat:@"DOWN — SCORE %ld", (long)_score] duration:3.0f];

	CCButton *retry = [CCButton buttonWithTitle:@"RETRY"];
	retry.positionType = CCPositionTypeNormalized;
	retry.position = ccp(0.5f, 0.42f);
	BOOL nightmare = _nightmare;
	__weak typeof(self) weakSelf = self;
	[retry setBlock:^(id sender) {
		DeepHardArena *strongSelf = weakSelf;
		if (!strongSelf) return;
		CCNode *parent = strongSelf.parent;
		DeepHardArena *arena = [[DeepHardArena alloc] initWithNightmare:nightmare];
		[strongSelf removeFromParent];
		[parent addChild:arena];
	}];
	[self addChild:retry z:120];
}

- (void)novaBlast
{
	for (NSInteger i = 0; i < 16; i++) {
		CGFloat ang = (M_PI * 2.0 * i) / 16.0;
		CGPoint aim = ccpAdd(_hero.position, ccp(cosf(ang) * 80, sinf(ang) * 80));
		[self fireProjectileFrom:_hero.position toward:aim speed:320 damage:2 hostile:NO];
	}
	[self burstRingAt:_hero.position color:[CCColor colorWithRed:0.4f green:1 blue:0.8f alpha:1]];
}

- (void)dashToward:(CGPoint)localPos
{
	if (!_alive || _dashCooldown > 0) return;
	_dashCooldown = _nightmare ? 1.35f : 1.7f;
	_invuln = MAX(_invuln, 0.35f);

	CGPoint dir = ccpSub(localPos, _hero.position);
	if (ccpLength(dir) < 1) dir = ccp(0, 1);
	dir = ccpNormalize(dir);
	CGPoint dest = ccpAdd(_hero.position, ccpMult(dir, _nightmare ? 150 : 130));
	_moveTarget = dest;

	[_hero runAction:[CCActionEaseOut actionWithAction:[CCActionMoveTo actionWithDuration:0.12f position:dest] rate:2.5f]];
	[self burstRingAt:_hero.position color:[CCColor colorWithRed:0.6f green:0.9f blue:1 alpha:1]];

	// Slash projectiles during dash
	for (NSInteger i = -1; i <= 1; i++) {
		CGFloat ang = ccpToAngle(dir) + i * 0.25f;
		CGPoint aim = ccpAdd(_hero.position, ccp(cosf(ang) * 60, sinf(ang) * 60));
		[self fireProjectileFrom:_hero.position toward:aim speed:380 damage:2 hostile:NO];
	}
}

#pragma mark FX / UI

- (void)burstRingAt:(CGPoint)pos color:(CCColor *)color
{
	CCSprite *ring = [CCSprite spriteWithImageNamed:@"Sprites/circle.png"];
	ring.position = pos;
	ring.scale = 0.15f;
	ring.color = color;
	ring.opacity = 0.85f;
	[self addChild:ring z:25];
	[ring runAction:[CCActionSequence actions:
		[CCActionSpawn actions:
			[CCActionEaseOut actionWithAction:[CCActionScaleTo actionWithDuration:0.35f scale:1.8f] rate:2],
			[CCActionFadeOut actionWithDuration:0.35f],
			nil],
		[CCActionCallBlock actionWithBlock:^{ [ring removeFromParent]; }],
		nil]];
}

- (void)flashBanner:(NSString *)text duration:(CCTime)duration
{
	[_bannerLabel stopAllActions];
	_bannerLabel.string = text;
	_bannerLabel.opacity = 0;
	_bannerLabel.scale = 0.7f;
	[_bannerLabel runAction:[CCActionSequence actions:
		[CCActionSpawn actions:
			[CCActionFadeIn actionWithDuration:0.12f],
			[CCActionEaseBackOut actionWithAction:[CCActionScaleTo actionWithDuration:0.2f scale:1.0f]],
			nil],
		[CCActionDelay actionWithDuration:duration],
		[CCActionFadeOut actionWithDuration:0.25f],
		nil]];
}

#pragma mark Input

- (void)aimToLocal:(CGPoint)localPos
{
	_moveTarget = localPos;
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	CGPoint p = [touch locationInNode:self];
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	static NSTimeInterval lastTap = 0;
	if (now - lastTap < 0.28) {
		[self dashToward:p];
	}
	lastTap = now;
	_pointerDown = YES;
	[self aimToLocal:p];
}

- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	if (!_pointerDown) return;
	[self aimToLocal:[touch locationInNode:self]];
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	_pointerDown = NO;
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	_pointerDown = NO;
}

#if __CC_PLATFORM_MAC
- (void)mouseDown:(NSEvent *)theEvent
{
	_pointerDown = YES;
	[self aimToLocal:[theEvent locationInNode:self]];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (!_pointerDown) return;
	[self aimToLocal:[theEvent locationInNode:self]];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	_pointerDown = NO;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self dashToward:[theEvent locationInNode:self]];
}
#endif

@end

#pragma mark - Test harness

@interface DeepHardDemoTest : TestBase @end

@implementation DeepHardDemoTest

- (NSArray *)testConstructors
{
	return @[
		@"setupSurvivalArenaTest",
		@"setupNightmareArenaTest",
		@"setupWarmupSandboxTest",
	];
}

- (void)setupSurvivalArenaTest
{
	self.subTitle = @"Drag to move Grossini's sister. Double-tap / right-click to dash. Survive escalating waves.";
	DeepHardArena *arena = [[DeepHardArena alloc] initWithNightmare:NO];
	[self.contentNode addChild:arena];
}

- (void)setupNightmareArenaTest
{
	self.subTitle = @"Nightmare pace: denser spawns, faster dashes, meaner bosses. Same deep systems, harder.";
	DeepHardArena *arena = [[DeepHardArena alloc] initWithNightmare:YES];
	[self.contentNode addChild:arena];
}

- (void)setupWarmupSandboxTest
{
	self.subTitle = @"Sandbox: action easing, particle bloom, and sister idle — no enemies.";

	CCNodeColor *bg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.08f green:0.09f blue:0.14f alpha:1]];
	bg.contentSizeType = CCSizeTypeNormalized;
	bg.contentSize = CGSizeMake(1, 1);
	[self.contentNode addChild:bg];

	CCSprite *sister = [CCSprite spriteWithImageNamed:@"Sprites/grossinis_sister.png"];
	sister.positionType = CCPositionTypeNormalized;
	sister.position = ccp(0.5f, 0.48f);
	sister.scale = 0.8f;
	[self.contentNode addChild:sister];

	[sister runAction:[CCActionRepeatForever actionWithAction:[CCActionSequence actions:
		[CCActionEaseElasticOut actionWithAction:[CCActionScaleTo actionWithDuration:0.6f scale:0.95f]],
		[CCActionEaseBounceOut actionWithAction:[CCActionScaleTo actionWithDuration:0.55f scale:0.75f]],
		[CCActionEaseSineInOut actionWithAction:[CCActionRotateBy actionWithDuration:0.8f angle:18]],
		[CCActionEaseSineInOut actionWithAction:[CCActionRotateBy actionWithDuration:0.8f angle:-18]],
		nil]]];

	CCParticleGalaxy *galaxy = [CCParticleGalaxy node];
	galaxy.positionType = CCPositionTypeNormalized;
	galaxy.position = ccp(0.5f, 0.48f);
	galaxy.scale = 0.55f;
	[self.contentNode addChild:galaxy z:-1];

	CCLabelTTF *hint = [CCLabelTTF labelWithString:@"She is warmed up.\nHit Survival or Nightmare next."
										  fontName:@"HelveticaNeue-Light"
										  fontSize:14];
	hint.positionType = CCPositionTypeNormalized;
	hint.position = ccp(0.5f, 0.18f);
	hint.horizontalAlignment = CCTextAlignmentCenter;
	[self.contentNode addChild:hint];
}

@end
