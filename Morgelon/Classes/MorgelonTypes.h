//
// Morgelon — body-horror evidence game (fiction)
// Threads. Ticks. Needles. Denial. Aspen in the blood.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MorgelonZone) {
	MorgelonZoneClinic = 0,
	MorgelonZoneBody,
	MorgelonZoneFlood,
	MorgelonZoneAspenVein,
	MorgelonZoneArchive
};

typedef NS_ENUM(NSInteger, MorgelonStat) {
	MorgelonStatThreads = 0,
	MorgelonStatEvidence,
	MorgelonStatDenial,
	MorgelonStatBloom,
	MorgelonStatPower
};

/// Player state carried between scenes.
@interface MorgelonState : NSObject

@property (nonatomic, assign) NSInteger threads;
@property (nonatomic, assign) NSInteger evidence;
@property (nonatomic, assign) NSInteger denial;   // how hard the world pushes back
@property (nonatomic, assign) NSInteger bloom;    // aspen growth in the blood (0–100)
@property (nonatomic, assign) NSInteger power;    // mischief made legible
@property (nonatomic, assign) BOOL dismissedByClinic;
@property (nonatomic, assign) BOOL vaccineUnknown;
@property (nonatomic, copy) NSString *lastLie;

+ (instancetype)sharedState;
- (void)reset;
- (void)pullThread;
- (void)recordEvidence:(NSString *)fragment;
- (void)receiveDenial;
- (void)floodZone;
- (BOOL)hasAscended; // appearance of mischief is evidence enough with power

@end
