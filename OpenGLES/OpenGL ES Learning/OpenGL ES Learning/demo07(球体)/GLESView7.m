//
//  GLESView7.m
//  OpenGL ES Learning
//
//  Created by 李超群 on 2019/2/13.
//  Copyright © 2019 李超群. All rights reserved.
//

#import "GLESView7.h"
#import "GLESUtils.h"
#import "OSSphere.h"
#import "GLESMath.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

typedef struct {
    GLuint position;
    GLuint textCoordinate;
    GLuint projectionMat;
    GLuint modelMat;
    GLuint viewMat;
}ShaderV;

@implementation GLESView7{
    CAEAGLLayer *_glLayer;
    EAGLContext *_glContext;
    GLuint _programHandle;
    ShaderV _lint;
    
    GLuint _VAO;
    GLuint  _numIndices;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setupContext];
        [self setupLayer];
        
        [self setupBuffer];
        [self setupShader];
        [self setupTextur];
        
        [self render];
        
    }
    return self;
}

+(Class)layerClass{
    return [CAEAGLLayer class];
}

-(void)setupContext{
    _glContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_glContext];
}

-(void)setupLayer{
    _glLayer = (CAEAGLLayer *)self.layer;
    _glLayer.opaque = YES;
    _glLayer.drawableProperties = @{
                                    kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8,
                                    kEAGLDrawablePropertyRetainedBacking : @(NO)
                                    };
}

-(void)setupBuffer{
    GLuint depthRenderBufferID;
    glGenRenderbuffers(1, &depthRenderBufferID);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBufferID);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
    
    GLuint colorRenderBufferID;
    glGenRenderbuffers(1, &colorRenderBufferID);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBufferID);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
    
    GLuint frameBufferID;
    glGenFramebuffers(1, &frameBufferID);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferID);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBufferID);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBufferID);
    
    glEnable(GL_DEPTH_TEST);
}

-(void)setupShader{
    NSString * vertextShaderPath = [[NSBundle mainBundle] pathForResource:@"VertextShader7" ofType:@"glsl"];
    NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"FragmentShader7" ofType:@"glsl"];
    GLuint vertextShader = [GLESUtils loadShader:GL_VERTEX_SHADER withFilepath:vertextShaderPath];
    GLuint framegmentShader = [GLESUtils loadShader:GL_FRAGMENT_SHADER withFilepath:fragmentShaderPath];
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertextShader);
    glAttachShader(_programHandle, framegmentShader);
    glLinkProgram(_programHandle);
    glUseProgram(_programHandle);
    
    [self setupShaderData];
}
-(void)setupShaderData{
    _lint.position = glGetAttribLocation(_programHandle, "position");
    _lint.textCoordinate = glGetAttribLocation(_programHandle, "textCoordinate");
    _lint.projectionMat = glGetUniformLocation(_programHandle, "projectionMat");
    _lint.modelMat = glGetUniformLocation(_programHandle, "modelMat");
    _lint.viewMat = glGetUniformLocation(_programHandle, "viewMat");

    glEnableVertexAttribArray(_lint.position);
    glEnableVertexAttribArray(_lint.textCoordinate);
}

-(void)setupTextur{
//    CGImageRef imgRef = [UIImage imageNamed:@"wall.jpg"].CGImage;
    CGImageRef imgRef = [UIImage imageNamed:@"earth-diffuse.jpg"].CGImage;
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    GLubyte *imgData = (GLubyte *)calloc(width * height * 4, sizeof(GLbyte));
    
    CGContextRef contextRef = CGBitmapContextCreate(imgData, width, height, 8, width * 4, CGImageGetColorSpace(imgRef), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imgRef);
    CGContextRelease(contextRef);
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imgData);

    free(imgData);
}

-(void)render{
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);

    GLfloat *_vertexData; // 顶点数据
    GLfloat *_texCoords;  // 纹理坐标
    GLushort    *_indices;    // 顶点索引
    GLint   _numVetex;   // 顶点数量

     _numIndices = generateSphere(200, 1.0, &(_vertexData), &(_texCoords), &_indices, &_numVetex);

    glGenVertexArrays(1, &_VAO);
    glBindVertexArray(_VAO);

    GLuint VBO, VBO1;
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &VBO1);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * _numVetex * 3, _vertexData, GL_STATIC_DRAW);
    glVertexAttribPointer(_lint.position, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), NULL);

    glBindBuffer(GL_ARRAY_BUFFER, VBO1);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * _numVetex * 2, _texCoords, GL_STATIC_DRAW);
    glVertexAttribPointer(_lint.textCoordinate, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GL_FLOAT), NULL);

    GLuint EBO;
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numIndices * sizeof(GLushort), _indices, GL_STATIC_DRAW);
    
    // - 设置显示区域
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    [self updateRender];

}

-(void)updateRender{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self setupShaderData];
    glBindVertexArray(_VAO);
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height; //长宽比
    
    // - 模型矩阵 (世界空间)
    KSMatrix4 modelMat;
    ksMatrixLoadIdentity(&modelMat);
    ksRotate(&modelMat, self.rote.roteY, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&modelMat, self.rote.roteX, 0.0, 1.0, 0.0); //绕Y轴
    ksScale(&modelMat, self.scale, self.scale, self.scale);
    glUniformMatrix4fv(_lint.modelMat, 1, GL_FALSE, (GLfloat*)&modelMat.m[0][0]);

    // - 观察矩阵 (观察空间)
    KSMatrix4 viewMat;
    ksMatrixLoadIdentity(&viewMat);
    ksTranslate(&viewMat, 0.0, 0.0, -5);
    glUniformMatrix4fv(_lint.viewMat, 1, GL_FALSE, (GLfloat*)&viewMat.m[0][0]);

    //投影矩阵 (裁剪空间)
    KSMatrix4 projectionMat;
    ksMatrixLoadIdentity(&projectionMat);
    ksPerspective(&projectionMat, 45.0, aspect, 0.1f, 100.0f); //透视变换，视角30°
    glUniformMatrix4fv(_lint.projectionMat, 1, GL_FALSE, (GLfloat*)&projectionMat.m[0][0]);
    
    glDrawElements(GL_TRIANGLES, _numIndices, GL_UNSIGNED_SHORT, 0);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

@end
