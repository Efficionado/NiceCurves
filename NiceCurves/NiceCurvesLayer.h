//
//  NiceCurvesLayer.h
//  Nice Curves
//
//  Created by Hans Meijers on 08/37/2013.
//  Copyright Snowtygar Productions 2013. All rights reserved.
//

#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

typedef enum {
	DraggingSpriteNone,
	DraggingSpriteControlPoint1,
	DraggingSpriteControlPoint2,
   	DraggingSpriteControlPoint3,
	DraggingSpriteControlPoint4
} DraggingSprite;

// NiceCurvesLayer
@interface NiceCurvesLayer : CCLayer
{
	CGSize size;
	
	DraggingSprite dragging;
	
	BOOL LeftToRight;
	
	// Bezier points
	CGPoint controlPoint1;
	CGPoint controlPoint2;
    CGPoint controlPoint3;
	CGPoint controlPoint4;
}

// returns a CCScene that contains the NiceCurvesLayer as the only child
+(CCScene *) scene;

@end
