//
//  WavefrontOBJ.h
//  OpenGLESLearn
//
//  Created by wang yang on 2017/6/20.
//  Copyright © 2017年 wangyang. All rights reserved.
//

#import "GLObject.h"

@interface WavefrontOBJ : GLObject
- (id)initWithGLContext:(GLContext *)context objFile:(NSString *)filePath;
- (void)update:(NSTimeInterval)timeSinceLastUpdate;
- (void)draw:(GLContext *)glContext;
@end
