//
//  OpenGLView.m
//  OpenGL
//
//  Created by Mahoone on 2020/8/3.
//  Copyright © 2020 Mahoone. All rights reserved.
//

#import "OpenGLView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import "../glm/glm.hpp"
#import "../glm/gtc/matrix_transform.hpp"
#import "../glm/gtc/type_ptr.hpp"

@interface OpenGLView ()
{
    GLuint _programId;
    glm::vec4 _glViewPortParameter;//giViewPort x,y,width,height
    glm::mat4 _ortho;
    GLuint textureWidth, textureHeight;
    
    NSArray <UIImageView*>*_moveViews;
}
@end

@implementation OpenGLView


#pragma mark - Life Cycle
- (void)dealloc {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    _context = nil;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

-(instancetype)init{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self render];
}

#pragma mark - Override

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupBuffer {
    glGenRenderbuffers(1, &_renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    glFramebufferRenderbuffer(
                              GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderbuffer);
    
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    _glViewPortParameter = glm::vec4(0,0,width,height);
    glViewport(0, 0, width, height);
    
    GLuint _depthRenderBuffer;
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(
                              GL_FRAMEBUFFER,
                              GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER,
                              _depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Error: Frame buffer is not completed.");
        exit(1);
    }
}
#pragma mark - Setup
- (void)setup {
    _screenScale = [[UIScreen mainScreen] scale];
    [self setContentScaleFactor:self.screenScale];
    self.userInteractionEnabled = false;
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = NO;
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
   
    [self setupBuffer];
   
    _programId = [self createProgramWithVertexShader:@"VertexShader.glsl" fragmentShader:@"FragmentShader.glsl"];
    
    textureWidth = (GLuint)(self.frame.size.width*self.screenScale);
    textureHeight = (GLuint)(self.frame.size.height*self.screenScale);
    
    _m = self.centerFrame.size.width * 2;
    _n = self.centerFrame.size.height * 2;
    CGSize size = self.centerFrame.size;
    GLfloat x = -size.width/2;
    GLfloat y = -size.height/2;
    GLfloat vertices[] = {
        x,               y, 0,       0,
        GLfloat(x+size.width/_m), y, GLfloat(1.0/_m),  0,
        GLfloat(x+size.width/_m), GLfloat(y+size.height/_n), GLfloat(1.0/_m),  GLfloat(1.0/_n),
        x,               GLfloat(y+size.height/_n), 0,      GLfloat( 1.0/_n)
    };
   
    glGenBuffers(1, &_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STREAM_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glActiveTexture(GL_TEXTURE1);
    _textureBack = [self generateTexture];
    [self copyTo:_textureBack fromImage:self.back];
    
    glActiveTexture(GL_TEXTURE0);
    _textureFront = [self generateTexture];
    [self copyTo:_textureFront fromImage:self.front];
    
    glUseProgram(_programId);
    glUniform1i(glGetUniformLocation(_programId, "s_front"),0);
    glUniform1i(glGetUniformLocation(_programId, "s_back"),1);
       
    int u_mn = glGetUniformLocation(_programId, "u_mn");
    size = self.centerFrame.size;
    glUniform4f(u_mn,_m,_n,size.width,size.height);
       
     x = self.frame.size.width/2;
     y = self.frame.size.height/2;
       
    _ortho = glm::ortho(-x,x,-y,y, (GLfloat)-100.f, (GLfloat)100.0f);
    int u_mvpMatrix = glGetUniformLocation(_programId, "u_mvpMatrix");
    glUniformMatrix4fv(u_mvpMatrix, 1,GL_FALSE, glm::value_ptr(_ortho));
    
}

- (void)copyTo:(GLuint)textureId fromImage:(UIImage*)image
{
  
    UIImage *backPageImage = image;
    
    glBindTexture(GL_TEXTURE_2D, textureId);
    
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = textureWidth * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, textureWidth, textureHeight, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGRect r = CGRectMake(0, 0, textureWidth, textureHeight);
    CGContextClearRect(context, r);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, textureWidth, 0);
    CGContextScaleCTM(context, -1, 1);
    CGContextDrawImage(context, r, backPageImage.CGImage);
    CGContextRestoreGState(context);
    
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)textureWidth, (GLsizei)textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    CGContextRelease(context);
}


#pragma mark - Shaders

- (GLuint)loadShader:(NSString *)filename type:(GLenum)type
{
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        return 0;
    }
    
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    NSString *shaderString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    const GLchar *shaderSource = [shaderString cStringUsingEncoding:NSUTF8StringEncoding];
    
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint success = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    
    if (success == 0) {
        char errorMsg[2048];
        glGetShaderInfoLog(shader, sizeof(errorMsg), NULL, errorMsg);
        NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
        NSLog(@"Failed to compile %@: %@", filename, errorString);
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (GLuint)createProgramWithVertexShader:(NSString *)vertexShaderFilename fragmentShader:(NSString *)fragmentShaderFilename
{
   
    GLuint vertexShader = [self loadShader:vertexShaderFilename type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self loadShader:fragmentShaderFilename type:GL_FRAGMENT_SHADER];
    GLuint prog = glCreateProgram();
    
    glAttachShader(prog, vertexShader);
    glAttachShader(prog, fragmentShader);
    glLinkProgram(prog);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    GLint linked = 0;
    glGetProgramiv(prog, GL_LINK_STATUS, &linked);
    if (linked == 0) {
        glDeleteProgram(prog);
        return 0;
    }
    
    return prog;
}


- (void)render {
  
    glDisable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    const CGFloat *color = CGColorGetComponents(self.backgroundColor.CGColor);
    if (color == NULL) {
        color = (CGFloat[]){1, 1, 1,1};
    }
    glClearColor(color[0], color[1], color[2], color[3]);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
   
    glUseProgram(_programId);
    
    glm::vec2 dir(self.direction.x,self.direction.y);
    glm::vec2 normalDir = glm::normalize(dir);
    
    glm::vec3 finalDir = glm::vec3(normalDir, self.radius);
    int directionId = glGetUniformLocation(_programId, "direction");
    glUniform3f(directionId, finalDir.x, finalDir.y, finalDir.z);
    
    
    CGFloat _xx = dir.x >= 0 ? -1  : 1;
    CGFloat _yy = dir.y >= 0 ? -1  : 1;
    glm::vec2 startP = glm::vec2(_xx *self.centerFrame.size.width/2, _yy*self.centerFrame.size.height/2);

    
    startP += 0.75f * dir ;
    glUniform2f(glGetUniformLocation(_programId, "point"),startP.x,startP.y);
    
    glUniform1i(glGetUniformLocation(_programId, "frontFacing"),self.frontFacing);
    
    glBindBuffer(GL_ARRAY_BUFFER,_vbo);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0,2, GL_FLOAT, GL_FALSE,4*sizeof(GLfloat),(void*)0);
    glVertexAttribPointer(1,2, GL_FLOAT, GL_FALSE,4*sizeof(GLfloat),(void*)(2*sizeof(GLfloat)));
        
    glDrawArraysInstanced(GL_TRIANGLE_FAN, 0, 4,_m*_n);
    
    // 做完所有绘制操作后，最终呈现到屏幕上
    [_context presentRenderbuffer:GL_RENDERBUFFER];

    
    CGFloat angle = atan(normalDir.x/normalDir.y);
    if (normalDir.y >= 0) {
        angle += M_PI;
    }
    [self.pFrames enumerateObjectsUsingBlock:^(NSValue * _Nonnull pF, NSUInteger index, BOOL * _Nonnull stop) {
        CGRect p = pF.CGRectValue;
        CGPoint points[] = {
                          p.origin,//topLeft
                          CGPointMake(p.origin.x + p.size.width, p.origin.y),//topRight
                          CGPointMake(p.origin.x, p.origin.y+p.size.height),//bottomLeft
                          CGPointMake(p.origin.x + p.size.width, p.origin.y+p.size.height),//bottomRight
                          CGPointMake(p.origin.x + p.size.width/2, p.origin.y+p.size.height/2),///center
                         };
                      
                      
        CGPoint outPoint = CGPointZero;
        NSInteger size = sizeof(points)/sizeof(CGPoint);
        BOOL should = NO;
                     
        for (NSInteger i = 0; i< size-1 && !should; i++) {///0...3
            should =  [self curlPoint:points[i] Point:startP Direction:finalDir OutInput:outPoint];
        }
        UIImageView *image = _moveViews[index];
        image.hidden = !should;
        
        if (should) {
            [self curlPoint:points[size-1] Point:startP Direction:finalDir OutInput:outPoint];
            image.center = CGPointMake(outPoint.x+8,outPoint.y+p.size.height/2);
            image.transform = CGAffineTransformMakeRotation(angle);
        }
    }];
    
}


///调用顶点着色器 代码，计算屏幕上的点，卷曲后的顶点坐标(注意screenCoordinate是父View的坐标系,outPoint是当前坐标系)
-(BOOL)curlPoint:(const CGPoint&)screenCoordinate Point:(const glm::vec2&)point Direction:(const glm::vec3&)direction OutInput:(CGPoint&)outPoint{
    glm::vec2 worldPoint = glm::vec2(screenCoordinate.x-self.centerFrame.size.width/2,-screenCoordinate.y+self.centerFrame.size.height/2);///将iOS屏幕坐标转换成 OpenGL中的世界坐标

    glm::vec3 pos = glm::vec3(worldPoint.x,worldPoint.y,0);//转换成3维，当前点的三维世界坐标
    glm::vec2 direction_xy = glm::vec2(direction.x,direction.y);
    
    float distance = glm::dot(point-worldPoint,direction_xy);
    BOOL ret = distance > 0.f;
    if(ret){
         glm::vec2 bottom = worldPoint + distance * direction_xy;
         float moreThanHalfCir = (distance -  M_PI * direction.z);
    
          if(moreThanHalfCir >= 0.f){//exceed
            glm::vec3 topPoint = glm::vec3(bottom, float(2) * direction.z);
            pos = topPoint + moreThanHalfCir * glm::vec3(direction_xy,0);
          }else{
    
            float angle = M_PI - distance / direction.z;
            float h = distance - sin(angle)*direction.z;
            float z = direction.z + cos(angle)*direction.z;
            glm::vec3 vD = pos + h * glm::vec3(direction_xy,0);
            pos = glm::vec3(vD.x,vD.y,z);
          }
    }
    

    glm::vec4 gl_Position = _ortho * glm::vec4(pos,1);///在顶点着色器中返回的结果

    outPoint = [self transformToScreenCoordinate:gl_Position];//OpenGL内部自动执行的操作
    
    return ret;
}


-(CGPoint)transformToScreenCoordinate:(const glm::vec4&)gl_Position{
    glm::vec3 clip = glm::vec3(gl_Position.x/gl_Position.w,gl_Position.y/gl_Position.w,gl_Position.z/gl_Position.w);//裁剪
    
    CGFloat x = (clip.x + 1)*(_glViewPortParameter.z/2) + _glViewPortParameter.x;
    CGFloat y = (clip.y + 1)*(_glViewPortParameter.w/2) + _glViewPortParameter.y;
    y = _glViewPortParameter.w - y;//Y轴方向 与 卡迪尔坐标系方向相反
    
   return CGPointMake(x,y);
}

- (GLuint)generateTexture
{
   
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return tex;
}

@end
