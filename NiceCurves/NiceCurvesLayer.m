//
//  NiceCurvesLayer.m
//  Nice Curves
//
//  Created by Hans Meijers on 08/37/2013.
//  Copyright Snowtygar Productions 2013. All rights reserved.
//


// Import the interfaces
#import "NiceCurvesLayer.h"

@interface BezierCurve

@end

float movementDuration = 3.0;

enum {
	kTagstarQuadBezier = 1001,
    kTagstarCubicBezier = 1002,
    kTagstarCatmullRom = 1003,
    kTagstarCardinal = 1004,
	kTagControlPoint1Sprite,
	kTagControlPoint1Label,
	kTagControlPoint2Sprite,
	kTagControlPoint2Label,
	kTagControlPoint3Sprite,
	kTagControlPoint3Label,
	kTagcontrolPoint4Sprite,
	kTagcontrolPoint4Label
};

NSString *const kControlPoint1Title = @"Control Point 1";
NSString *const kControlPoint2Title = @"Control Point 2";
NSString *const kControlPoint3Title = @"Control Point 3";
NSString *const kcontrolPoint4Title = @"Control Point 4";

ccColor3B colorQuadBezier;
ccColor3B colorCubicBezier;
ccColor3B colorCatmullRom;
ccColor3B colorCardinal;

@interface NiceCurvesLayer(Private)
-(void)startSpriteMovement;
-(void)performSpriteMovement;

-(NSString *)formatPoint:(CGPoint)point named:(NSString *)name;

-(BOOL)containsTouchLocation:(UITouch *)touch;

@end

// NiceCurvesLayer implementation
@implementation NiceCurvesLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	NiceCurvesLayer *layer = [NiceCurvesLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        colorQuadBezier = ccc3(0, 255, 0);
        colorCubicBezier = ccc3(255, 255, 0);
        colorCatmullRom = ccc3(255, 0, 255);
        colorCardinal = ccc3(0, 255, 255);

		// Setup touches
		[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:NO];
		
		// ask director the the window size
		size = [[CCDirector sharedDirector] winSize];
		
		// Now lets add the green star sprite for the bezier
		CCSprite *starQuadBezier = [CCSprite spriteWithFile:@"star-white.png"];
        starQuadBezier.color = colorQuadBezier;
		[self addChild:starQuadBezier z:3 tag:kTagstarQuadBezier];

		// And lets add the red star sprite for the catmullrom
		CCSprite *startCubicBezier = [CCSprite spriteWithFile:@"star-white.png"];
        startCubicBezier.color = colorCubicBezier;
		[self addChild:startCubicBezier z:3 tag:kTagstarCubicBezier];

		// And lets add the red star sprite for the catmullrom
		CCSprite *startCatmullRom = [CCSprite spriteWithFile:@"star-white.png"];
        startCatmullRom.color = colorCatmullRom;
		[self addChild:startCatmullRom z:3 tag:kTagstarCatmullRom];

        // And lets add the blue star sprite for the cardinal spline
		CCSprite *starCardinal = [CCSprite spriteWithFile:@"star-white.png"];
        starCardinal.color = colorCardinal;
		[self addChild:starCardinal z:3 tag:kTagstarCardinal];

		// Set not dragging
		dragging = DraggingSpriteNone;
		
		// Set left to right by default
		LeftToRight = YES;
		
		// Start the sprites movement
		[self startSpriteMovement];
        
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// Remove delegate for touches
//    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self] ;

	// don't forget to call "super dealloc"
	[super dealloc];
}

-(NSString *)formatPoint:(CGPoint)point named:(NSString *)name
{
	return [NSString stringWithFormat:@"%@:(%.2f,%.2f)",name,point.x, point.y];
}

#pragma mark - Scene Management

-(void)startSpriteMovement 
{
	// Setup default positions for control points for the bezier/catmullrom/cardinal
	controlPoint1 = ccp(30, 100);
	controlPoint2 = ccp(190, 255);
  	controlPoint3 = ccp(320, 60);
	controlPoint4 = ccp(450, 280);

	// Add some sprites for these points, so its easier for us to see
	CCSprite *controlPoint1Sprite = [CCSprite spriteWithFile:@"point1_green.png"];
	controlPoint1Sprite.position = controlPoint1;
	[self addChild:controlPoint1Sprite z:2 tag:kTagControlPoint1Sprite];
	
	CCSprite *controlPoint2Sprite = [CCSprite spriteWithFile:@"point2_red.png"];
	controlPoint2Sprite.position = controlPoint2;
	[self addChild:controlPoint2Sprite z:2 tag:kTagControlPoint2Sprite];

	CCSprite *controlPoint3Sprite = [CCSprite spriteWithFile:@"point3_orange.png"];
	controlPoint3Sprite.position = controlPoint3;
	[self addChild:controlPoint3Sprite z:2 tag:kTagControlPoint3Sprite];
    
	CCSprite *controlPoint4Sprite = [CCSprite spriteWithFile:@"point4_blue.png"];
	controlPoint4Sprite.position = controlPoint4;
	[self addChild:controlPoint4Sprite z:2 tag:kTagcontrolPoint4Sprite];

	// Add some labels for debugging
	NSString *fontName = @"Marker Felt";
	float fontSize = 11.0f;
	CCLabelTTF *controlPoint1Label = [CCLabelTTF labelWithString:[self formatPoint:controlPoint1 named:kControlPoint1Title] fontName:fontName fontSize:fontSize];
	controlPoint1Label.position = ccp(90, size.height - 10);
	[self addChild:controlPoint1Label z:1 tag:kTagControlPoint1Label];
	
	CCLabelTTF *controlPoint2Label = [CCLabelTTF labelWithString:[self formatPoint:controlPoint2 named:kControlPoint2Title] fontName:fontName fontSize:fontSize];
	controlPoint2Label.position = ccp(size.width / 2, size.height - 10);
	[self addChild:controlPoint2Label z:1 tag:kTagControlPoint2Label];
	
	CCLabelTTF *controlPoint3Label = [CCLabelTTF labelWithString:[self formatPoint:controlPoint3 named:kControlPoint3Title] fontName:fontName fontSize:fontSize];
	controlPoint3Label.position = ccp(90, size.height - 30);
	[self addChild:controlPoint3Label z:1 tag:kTagControlPoint3Label];

	CCLabelTTF *controlPoint4Label = [CCLabelTTF labelWithString:[self formatPoint:controlPoint4 named:kcontrolPoint4Title] fontName:fontName fontSize:fontSize];
	controlPoint4Label.position = ccp(size.width / 2, size.height -30);
	[self addChild:controlPoint4Label z:1 tag:kTagcontrolPoint4Label];
	
    CCLabelTTF *quadBezierLabel = [CCLabelTTF labelWithString:@"- Quad Bezier -" fontName:fontName fontSize:fontSize+2];
	quadBezierLabel.position = ccp(size.width / 2 - 130, 30);
    quadBezierLabel.color = colorQuadBezier;
	[self addChild:quadBezierLabel z:1];

    CCLabelTTF *cubicBezierLabel = [CCLabelTTF labelWithString:@"- Cubic Bezier -" fontName:fontName fontSize:fontSize+2];
	cubicBezierLabel.position = ccp(size.width / 2 - 40, 30);
    cubicBezierLabel.color = colorCubicBezier;
	[self addChild:cubicBezierLabel z:1];
    
    CCLabelTTF *cmrLabel = [CCLabelTTF labelWithString:@"- Catmull-Rom spline -" fontName:fontName fontSize:fontSize+2];
	cmrLabel.position = ccp(size.width / 2 + 65, 30);
    cmrLabel.color = ccc3(255,0,255);
	[self addChild:cmrLabel z:1];
    
    CCLabelTTF *cardinalLabel = [CCLabelTTF labelWithString:@"- Cardinal spline -" fontName:fontName fontSize:fontSize+2];
	cardinalLabel.position = ccp(size.width /2 + 180, 30);
    cardinalLabel.color = ccc3(0, 255, 255);
    [self addChild:cardinalLabel z:1];

	// Set starting position for the sprites
	[self getChildByTag:kTagstarQuadBezier].position = controlPoint1;
	[self getChildByTag:kTagstarCubicBezier].position = controlPoint1;
	[self getChildByTag:kTagstarCatmullRom].position = controlPoint1;
	[self getChildByTag:kTagstarCardinal].position = controlPoint1;

	// Perform the movement
	[self performSpriteMovement];
}

#pragma mark - Moving objects along the curves

-(void)performSpriteMovement
{
    [self moveQuadBezier];
    [self moveCubicBezier];
    [self moveCatmullRom];
    [self moveCardinalSpline];
    [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:movementDuration]
                                      two:[CCCallBlock actionWithBlock:^{
        [self performSpriteMovement];
    }]]];
}

-(void) moveQuadBezier
{
	CCSprite *star = (CCSprite *)[self getChildByTag:kTagstarQuadBezier];
	id bezierAction;
    // 1 - Setup the Quad Bezier Curve
	ccBezierConfig bezierQuad;
    
	// Create the bezier path
    bezierQuad.controlPoint_1 = controlPoint1;
    bezierQuad.controlPoint_2 = controlPoint2;
    bezierQuad.endPosition = controlPoint4;

	// Create the bezier action
	bezierAction = [CCBezierTo actionWithDuration:movementDuration bezier:bezierQuad];
    
    star.position = controlPoint1;
    
    // Run the action sequence for the Bezier curve
	[star runAction:bezierAction];
}

-(void) moveCubicBezier
{
	CCSprite *star = (CCSprite *)[self getChildByTag:kTagstarCubicBezier];
	id bezierAction;
    // 1 - Setup the Quad Bezier Curve
	ccBezierConfig bezierQuad;
    
	// Create the bezier path
    bezierQuad.controlPoint_1 = controlPoint2;
    bezierQuad.controlPoint_2 = controlPoint3;
    bezierQuad.endPosition = controlPoint4;

	// Create the bezier action
	bezierAction = [CCBezierTo actionWithDuration:movementDuration bezier:bezierQuad];
    
    star.position = controlPoint1;
    
    // Run the action sequence for the Bezier curve
	[star runAction:bezierAction];
}

-(void) moveCatmullRom
{
    CCSprite *star = (CCSprite *)[self getChildByTag:kTagstarCatmullRom];

	// Setup the actions
    id catmullromAction;

    CCPointArray *pointArray = [CCPointArray arrayWithCapacity:4];
    [pointArray addControlPoint:controlPoint1];
    [pointArray addControlPoint:controlPoint2];
    [pointArray addControlPoint:controlPoint3];
    [pointArray addControlPoint:controlPoint4];
    
    catmullromAction = [CCCatmullRomTo actionWithDuration:movementDuration points:pointArray];

    star.position = controlPoint1;
    
	CCAction *cmrAction = [CCSequence actions: catmullromAction, nil];
	[star runAction:cmrAction];
}

-(void) moveCardinalSpline
{
    CCSprite *star = (CCSprite *)[self getChildByTag:kTagstarCardinal];

    CCPointArray *pointArray = [CCPointArray arrayWithCapacity:4];
    [pointArray addControlPoint:controlPoint1];
    [pointArray addControlPoint:controlPoint2];
    [pointArray addControlPoint:controlPoint3];
    [pointArray addControlPoint:controlPoint4];
    CCCardinalSplineTo *cardinalsplineAction = [CCCardinalSplineTo actionWithDuration:movementDuration points:pointArray tension:0.0f];
    
    star.position = controlPoint1;

	CCAction *cardinalAction = [CCSequence actions: cardinalsplineAction, nil];
	[star runAction:cardinalAction];
}


#pragma mark - Drawing the curves

-(void) draw
{
    [self drawQuadBezier];
    [self drawCubicBezier];
    [self drawCatmullRom];
    [self drawCardinalSpline];
}

-(void) drawQuadBezier
{
	// draw quad bezier path
    ccDrawColor4B( colorQuadBezier.r, colorQuadBezier.g, colorQuadBezier.b, 255);
    glLineWidth(2.0f);
	ccDrawQuadBezier(controlPoint1, controlPoint2, controlPoint4, 100);
}

-(void) drawCubicBezier
{
    ccDrawColor4B( colorCubicBezier.r, colorCubicBezier.g, colorCubicBezier.b, 255);
    glLineWidth(2.0f);
	ccDrawCubicBezier(controlPoint1, controlPoint2, controlPoint3, controlPoint4, 100);
}

-(void) drawCatmullRom
{
    CCPointArray* pointArray = [CCPointArray arrayWithCapacity:4];
    [pointArray addControlPoint:controlPoint1];
    [pointArray addControlPoint:controlPoint2];
    [pointArray addControlPoint:controlPoint3];
    [pointArray addControlPoint:controlPoint4];
    
    ccDrawColor4B( colorCatmullRom.r, colorCatmullRom.g, colorCatmullRom.b, 255);
    glLineWidth(2.0f);
    ccDrawCatmullRom(pointArray, 100);
}

-(void) drawCardinalSpline
{
    CCPointArray* pointArray = [CCPointArray arrayWithCapacity:4];
    [pointArray addControlPoint:controlPoint1];
    [pointArray addControlPoint:controlPoint2];
    [pointArray addControlPoint:controlPoint3];
    [pointArray addControlPoint:controlPoint4];

    ccDrawColor4B(colorCardinal.r, colorCardinal.g, colorCardinal.b, 255);

    glLineWidth(2.0f);
    ccDrawCardinalSpline(pointArray, 0.0f, 100);
}

#pragma mark - TouchHandler delegate methods

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{        
	// Check the touch locations
    if (![self containsTouchLocation:touch]) return NO;
    	
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	// Error checking
	if(dragging == DraggingSpriteNone)
		return;
    
	// Peform the move and drag of the correct sprite
    CGPoint location = [touch locationInView: [touch view]];
    CGPoint lastLocation = [touch previousLocationInView: [touch view]];
    location = [[CCDirector sharedDirector] convertToGL: location];
    lastLocation = [[CCDirector sharedDirector] convertToGL: lastLocation];
	
	CCSprite *sprite;
	CCLabelTTF *label;
	
	switch (dragging) {
		case DraggingSpriteControlPoint1:
			// Update the position
			sprite = (CCSprite *) [self getChildByTag:kTagControlPoint1Sprite];
			controlPoint1 = lastLocation;
			
			// Update the label
			label = (CCLabelTTF *)[self getChildByTag:kTagControlPoint1Label];
			[label setString:[self formatPoint:controlPoint1 named:kControlPoint1Title]];
			
			break;
		case DraggingSpriteControlPoint2:
			// Update the position
			sprite = (CCSprite *) [self getChildByTag:kTagControlPoint2Sprite];
			controlPoint2 = lastLocation;
			
			// Update the label
			label = (CCLabelTTF *)[self getChildByTag:kTagControlPoint2Label];
			[label setString:[self formatPoint:controlPoint2 named:kControlPoint2Title]];

			break;
		case DraggingSpriteControlPoint3:
			// Update the position
			sprite = (CCSprite *) [self getChildByTag:kTagControlPoint3Sprite];
			controlPoint3 = lastLocation;
			
			// Update the label
			label = (CCLabelTTF *)[self getChildByTag:kTagControlPoint3Label];
			[label setString:[self formatPoint:controlPoint3 named:kControlPoint3Title]];
            
			break;
		case DraggingSpriteControlPoint4:
			// Update the position
			sprite = (CCSprite *) [self getChildByTag:kTagcontrolPoint4Sprite];
			controlPoint4 = lastLocation;
			
			// Update the label
			label = (CCLabelTTF *)[self getChildByTag:kTagcontrolPoint4Label];
			[label setString:[self formatPoint:controlPoint4 named:kcontrolPoint4Title]];

			break;
		default:
			break;
	}
	
	sprite.position = lastLocation;	
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	// Not dragging anymore
	dragging = DraggingSpriteNone;
}

- (BOOL)containsTouchLocation:(UITouch *)touch {
	
	// Checking bounds
	
	// Point 1
	CCSprite *controlPoint1Sprite = (CCSprite *) [self getChildByTag:kTagControlPoint1Sprite];
    CGRect controlPoint1Rect = [controlPoint1Sprite boundingBox];
    
	if(CGRectContainsPoint(controlPoint1Rect, [self convertTouchToNodeSpace:touch])) {
		dragging = DraggingSpriteControlPoint1;
		return YES;
	}

	// Point 2
	CCSprite *controlPoint2Sprite = (CCSprite *) [self getChildByTag:kTagControlPoint2Sprite];
    CGRect controlPoint2Rect = [controlPoint2Sprite boundingBox];
    
	if(CGRectContainsPoint(controlPoint2Rect, [self convertTouchToNodeSpace:touch])) {
		dragging = DraggingSpriteControlPoint2;
		return YES;
	}

	// Point 3
	CCSprite *controlPoint3Sprite = (CCSprite *) [self getChildByTag:kTagControlPoint3Sprite];
    CGRect controlPoint3Rect = [controlPoint3Sprite boundingBox];
    
	if(CGRectContainsPoint(controlPoint3Rect, [self convertTouchToNodeSpace:touch])) {
		dragging = DraggingSpriteControlPoint3;
		return YES;
	}
	
	// End Point
	CCSprite *controlPoint4Sprite = (CCSprite *) [self getChildByTag:kTagcontrolPoint4Sprite];
    CGRect controlPoint4Rect = [controlPoint4Sprite boundingBox];
    
	if(CGRectContainsPoint(controlPoint4Rect, [self convertTouchToNodeSpace:touch])) {
		dragging = DraggingSpriteControlPoint4;
		return YES;
	}
	
	return NO;
}

@end
