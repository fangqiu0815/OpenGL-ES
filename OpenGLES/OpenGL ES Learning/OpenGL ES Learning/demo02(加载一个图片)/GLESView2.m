
//
//  GLESView2.m
//  OpenGL ES Learning
//
//  Created by 李超群 on 2019/1/26.
//  Copyright © 2019 李超群. All rights reserved.
//

#import "GLESView2.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GLESUtils.h"

typedef struct {
    GLuint position;
    GLuint textCoor;
}CustomLint;

typedef struct {
    float position0[3];
    float position1[2];
}CustomVertex;


@implementation GLESView2{
    CAEAGLLayer *_glLayer;
    EAGLContext *_glContext;
    
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    GLint _programHandle;
    
    CustomLint _lint;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self setuplayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgramHandle];
    [self setupTexture];
    
    [self render];
    
}

+(Class)layerClass{
    return [CAEAGLLayer class];
}

- (void)setuplayer{
    _glLayer =  (CAEAGLLayer *)self.layer;
    _glLayer.opaque = YES;
    [_glLayer setDrawableProperties:@{
                                      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8,
                                      kEAGLDrawablePropertyRetainedBacking : @(NO)
                                      }];
}

-(void)setupContext{
    _glContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_glContext];
}

-(void)setupRenderBuffer{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
}

-(void)setupFrameBuffer{
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

-(void)setupProgramHandle{
    NSString * vertextShaderPath = [[NSBundle mainBundle] pathForResource:@"VertextShader2" ofType:@"glsl"];
    NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"FragmentShader2" ofType:@"glsl"];
    
    GLuint vertextShader = [GLESUtils loadShader:GL_VERTEX_SHADER withFilepath:vertextShaderPath];
    GLuint framegmentShader = [GLESUtils loadShader:GL_FRAGMENT_SHADER withFilepath:fragmentShaderPath];
    
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertextShader);
    glAttachShader(_programHandle, framegmentShader);
    glLinkProgram(_programHandle);
    glUseProgram(_programHandle);
    
    _lint.position = glGetAttribLocation(_programHandle, "position");
    _lint.textCoor = glGetAttribLocation(_programHandle, "textCoordinate");
    
    glEnableVertexAttribArray(_lint.position);
    glEnableVertexAttribArray(_lint.textCoor);
}

- (void)setupTexture{

    CGImageRef imgRef = [UIImage imageNamed:@"kakaxi.jpg"].CGImage;
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    GLubyte *imgData = (GLubyte *)calloc(width * height * 4, sizeof(GLbyte));

    CGContextRef contextRef = CGBitmapContextCreate(imgData, width, height, 8, width * 4, CGImageGetColorSpace(imgRef), kCGImageAlphaPremultipliedLast);
    
    // - 翻转纹理坐标
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextTranslateCTM(contextRef, 0, rect.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // - 绘制图片
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imgRef);
    CGContextRelease(contextRef);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imgData);
    free(imgData);
}

-(void)render{
    glClearColor(0, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    CustomVertex lint1 = {.position0 = {0.5,  -0.5, 0}, .position1 = {1.0, 0.0}};
    CustomVertex lint2 = {.position0 = {-0.5,  0.5, 0}, .position1 = {0.0, 1.0}};
    CustomVertex lint3 = {.position0 = {-0.5,  -0.5, 0}, .position1 = {0.0, 0.0}};

    CustomVertex lint4 = {.position0 = {0.5,  0.5, 0}, .position1 = {1.0, 1.0}};
    CustomVertex lint5 = {.position0 = {-0.5,  0.5, 0}, .position1 = {0.0, 1.0}};
    CustomVertex lint6 = {.position0 = {0.5,  -0.5, 0}, .position1 = {1.0, 0.0}};
    CustomVertex vertices[] ={lint1, lint2, lint3, lint4, lint5, lint6};

    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    glVertexAttribPointer(_lint.position, 3, GL_FLOAT, GL_FALSE,  sizeof(GLfloat) * 5, NULL);
    glVertexAttribPointer(_lint.textCoor, 2, GL_FLOAT, GL_FALSE,  sizeof(GLfloat) * 5, (float *)NULL + 3);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)destoryRenderAndFrameBuffer{
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    
    glDeleteBuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
}

@end
