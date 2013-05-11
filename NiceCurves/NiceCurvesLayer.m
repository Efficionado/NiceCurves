//
//  NiceCurvesLayer.m
//  Nice Curves
//
//  Created by Hans Meijers on 08/37/2013.
//  Copyright Snowtygar Productions 2013. All rights reserved.
//


// Import the interfaces
#import "NiceCurvesLayer.h"

enum {
	kTagstarGreenSprite = 1001,
    kTagstarRedSprite = 1002,
    kTagstarBlueSprite = 1003,
	kTagstarGreenBezierAction,
    kTagstarRedCatMullRomAction,
    kTagstarBlueCardinalAction,
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
		
		// Setup touches
		[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:NO];
		
		// ask director the the window size
		size = [[CCDirector sharedDirector] winSize];
		
		// Now lets add the green star sprite for the bezier
		CCSprite *starGreenSprite = [CCSprite spriteWithFile:@"star-green.png"];
		starGreenSprite.position = ccp(size.width/2, 10);
		[self addChild:starGreenSprite z:3 tag:kTagstarGreenSprite];
		
		// And lets add the red star sprite for the catmullrom
		CCSprite *starRedSprite = [CCSprite spriteWithFile:@"star-red.png"];
		starRedSprite.position = ccp(size.width/2, 10);
		[self addChild:starRedSprite z:3 tag:kTagstarRedSprite];

        // And lets add the blue star sprite for the cardinal spline
		CCSprite *starBlueSprite = [CCSprite spriteWithFile:@"star-blue.png"];
		starBlueSprite.position = ccp(size.width/2, 10);
		[self addChild:starBlueSprite z:3 tag:kTagstarBlueSprite];

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

-(void)startSpriteMovement 
{
	CCSprite *starGreenSprite = (CCSprite *)[self getChildByTag:kTagstarGreenSprite];
    CCSprite *starRedSprite = (CCSprite *)[self getChildByTag:kTagstarRedSprite];
    CCSprite *starBlueSprite = (CCSprite *)[self getChildByTag:kTagstarBlueSprite];

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
	
    CCLabelTTF *bezierLabel = [CCLabelTTF labelWithString:@"- Bezier -" fontName:fontName fontSize:fontSize+2];
	bezierLabel.position = ccp(size.width / 2 - 100, 30);
    bezierLabel.color = ccc3(0,255,0);
	[self addChild:bezierLabel z:1];
    
    CCLabelTTF *cmrLabel = [CCLabelTTF labelWithString:@"- Catmull-Rom spline -" fontName:fontName fontSize:fontSize+2];
	cmrLabel.position = ccp(size.width / 2, 30);
    cmrLabel.color = ccc3(255,0,255);
	[self addChild:cmrLabel z:1];
    
    CCLabelTTF *cardinalLabel = [CCLabelTTF labelWithString:@"- Cardinal spline -" fontName:fontName fontSize:fontSize+2];
	cardinalLabel.position = ccp(size.width /2 +130, 30);
    cardinalLabel.color = ccc3(0, 255, 255);
    [self addChild:cardinalLabel z:1];

	// Set starting position for the sprites
	starGreenSprite.position = controlPoint1;
    starRedSprite.position = controlPoint1;
    starBlueSprite.position = controlPoint1;

	// Perform the movement
	[self performSpriteMovement];
}

-(void)performSpriteMovement
{
	// Get the sprite
	CCSprite *starGreenSprite = (CCSprite *)[self getChildByTag:kTagstarGreenSprite];
    CCSprite *starRedSprite = (CCSprite *)[self getChildByTag:kTagstarRedSprite];
    CCSprite *starBlueSprite = (CCSprite *)[self getChildByTag:kTagstarBlueSprite];

	// Setup the actions
	id bezierAction;
    id catmullromAction;
    id cardinalsplineAction;
    id callback = [CCCallFunc actionWithTarget:self selector:@selector(curveFinished:)];
    
    // 1 - Setup the Bezier Curve
	ccBezierConfig bezier;
    
	// Create the bezier path
    bezier.controlPoint_1 = controlPoint1;
    bezier.controlPoint_2 = controlPoint2;
    bezier.endPosition = controlPoint4;

	// Creat the bezier action
	bezierAction = [CCBezierTo actionWithDuration:3.0 bezier:bezier];
    
    starGreenSprite.position = controlPoint1;
    
    // Run the action sequence for the Bezier curve
	CCAction *arcAction = [CCSequence actions: bezierAction, callback, nil];
	arcAction.tag = kTagstarGreenBezierAction;
	[starGreenSprite runAction:arcAction];

    // setup the PointArray for Catmulrom spline and Cardinal spline
    CCPointArray* pointArray = [CCPointArray arrayWithCapacity:4];
    [pointArray addControlPoint:controlPoint1];
    [pointArray addControlPoint:controlPoint2];
    [pointArray addControlPoint:controlPoint3];
    [pointArray addControlPoint:controlPoint4];
    
    catmullromAction = [CCCatmullRomTo actionWithDuration:3 points:pointArray];

    starRedSprite.position = controlPoint1;
    
	// Run the action sequence for the Catmullrom Curve
	CCAction *cmrAction = [CCSequence actions: catmullromAction, nil];
	cmrAction.tag = kTagstarRedCatMullRomAction;
	[starRedSprite runAction:cmrAction];
    
    // 3 - Setup the Cardinal spline
    
    cardinalsplineAction = [CCCardinalSplineTo actionWithDuration:2.5 points:pointArray tension:0.0f];
    
    starBlueSprite.position = controlPoint1;

	// Run the action sequence for the Cardinal Spline Curve
	CCAction *cardinalAction = [CCSequence actions: cardinalsplineAction, nil];
	cardinalAction.tag = kTagstarBlueCardinalAction;
	[starBlueSprite runAction:cardinalAction];
    
}

-(void)curveFinished:(id)sender 
{
	// Perform the movement
	[self performSpriteMovement];
}

-(void) draw
{	
	// draw quad bezier path
    ccDrawColor4B(0, 255, 0, 255);
    glLineWidth(2.0f);
	ccDrawQuadBezier(controlPoint1, controlPoint2, controlPoint4, 100);
    
    // setup the PointArray for Catmulrom spline and Cardinal spline
    CCPointArray* pointArray = [CCPointArray arrayWithCapacity:4];
    [pointArray addControlPoint:controlPoint1];
    [pointArray addControlPoint:controlPoint2];
    [pointArray addControlPoint:controlPoint3];
    [pointArray addControlPoint:controlPoint4];
    
    ccDrawColor4B(255, 0, 255, 255);
    glLineWidth(2.0f);
    ccDrawCatmullRom(pointArray, 100);
    
    // draw Cardinal spline
    ccDrawColor4B(0, 255, 255, 255);
    glLineWidth(2.0f);
    ccDrawCardinalSpline(pointArray, 0.0f, 100);
    
}

-(NSString *)formatPoint:(CGPoint)point named:(NSString *)name
{
	return [NSString stringWithFormat:@"%@:(%.2f,%.2f)",name,point.x, point.y];
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
