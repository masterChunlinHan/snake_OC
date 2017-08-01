//
//  ViewController.m
//  mySnake
//
//  Created by 韩春林 on 2017/7/30.
//  Copyright © 2017年 韩春林. All rights reserved.
//

#import "ViewController.h"
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width//屏幕的高度
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height//屏幕宽度
#define LINECOUNT 30    //地图上可显示的行数，这里规定地图是正方形，所以只需要一个数
#define BOXWIDTH  SCREENHEIGHT/LINECOUNT  //每格的宽度，既是食物的宽度也是每节蛇身的宽度

@interface ViewController ()
    @property(nonatomic,strong)UIView *map;//地图只有一个，定义成全局的
    @property(nonatomic,strong)UIView *food;//食物也只有一个
    @property(nonatomic,assign)NSInteger foodx;//食物的x坐标,以格子的宽度为单位
    @property(nonatomic,assign)NSInteger foody;//食物的y坐标
    @property(nonatomic,strong)NSMutableArray *body;//蛇的身体是变化的，所以用一个可变数组来存
    @property(nonatomic,strong)NSTimer *timer;//定时器
    @property(nonatomic,assign)NSInteger directionCode;//定义一个数字来代表方向0，1，2，3分别代表上下左右
    @property(nonatomic,assign)float time;//定时器的时间间隔，默认为0.5秒走一步
@end

@implementation ViewController
//初始化定时器的间隔
-(float)time{
    if(!_time){
        _time=0.5;
    }
    return _time;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
     [self createMap];
    //不会变的按钮只在开始创建一份
    //添加重置按钮
    [self createReloadButton];
    //添加开始暂停按钮
    [self createControlButtons];
    //添加方向键
    [self createDirectionButtons];

}
//reload方法，执行之后一切重置，移除地图上的所有东西，并重新创建
-(void)reload{
    self.body = nil;
    for(UIView *subview in self.map.subviews){
        if(subview!=self.food){
        [subview removeFromSuperview];
        }
        
    }
    [self createFood];
    [self createSnake];
    [self createTimer];
}
//创建重置按钮
-(void)createReloadButton{
    UIButton *reloadBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, (SCREENWIDTH-SCREENHEIGHT)/2, SCREENHEIGHT/3)];
    [self.view addSubview:reloadBtn];
    [reloadBtn setTitle:@"重置/开始" forState:UIControlStateNormal];
    reloadBtn.backgroundColor = [UIColor orangeColor];
    [reloadBtn addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
}
//创建地图
-(void)createMap{
    //先判断地图是否已经存在，如果存在就不再创建
    if(!self.map){
    self.map = [[UIView alloc]initWithFrame:CGRectMake(0,0, SCREENHEIGHT, SCREENHEIGHT)];
    [self.view addSubview:self.map];
    UIColor *lightColor = [UIColor colorWithRed:238/255.0 green:238/255.0 blue:238/255.0 alpha:1];
    self.map.backgroundColor =lightColor;
    self.map.center = self.view.center;
    }

}
//创建食物，每次刷新时都会调用这个方法
-(void)createFood{
    //先判断食物是否已经存在，如果存在就不再创建
    if(!self.food){
    self.food = [[UIView alloc]initWithFrame:CGRectMake(0,0, BOXWIDTH, BOXWIDTH)];
        UIColor *foodColor = [UIColor redColor];
        self.food.backgroundColor = foodColor;
        [self.map addSubview:self.food];
    }
    //每次刷新食物的坐标都是一个随机值
    self.foodx = arc4random()%LINECOUNT;
    self.foody = arc4random()%LINECOUNT;
    self.food.frame = CGRectMake(self.foodx*BOXWIDTH, self.foody*BOXWIDTH, BOXWIDTH, BOXWIDTH);

}
//创建蛇，每次刷新时先让蛇的身体坐标发生改变，再调用这个方法，让蛇重新显示
-(void)createSnake{
    //先判断食物是否已经存在，如果存在就不再创建
    if(!self.body){
        //初始化蛇前进的方向为向右
        self.directionCode = 3;
        //初始化蛇的身体，开始时只有一个头，两节身体，头为红色，身体为蓝色
        self.body = [NSMutableArray arrayWithArray:@[
                                                     @{@"bodyx":@"2",@"bodyy":@"2",@"color":[UIColor redColor]},
                                                     @{@"bodyx":@"1",@"bodyy":@"2",@"color":[UIColor blueColor]},
                                                     @{@"bodyx":@"0",@"bodyy":@"2",@"color":[UIColor blueColor]}
                                                     ]];
    }
    for (int i=0; i<self.body.count; i++) {
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:self.body[i]];
        UIView *body = mDic[@"body"];
        if(!body){
            body = [[UIView alloc]initWithFrame:CGRectMake(0, 0, BOXWIDTH, BOXWIDTH)];
             [self.map addSubview:body];
            [mDic setObject:body forKey:@"body"];
        }

        float bodyx =BOXWIDTH*[mDic[@"bodyx"] intValue];
        float bodyy =BOXWIDTH*[mDic[@"bodyy"] intValue];
        body.frame = CGRectMake(bodyx, bodyy, BOXWIDTH, BOXWIDTH);
        body.backgroundColor = mDic[@"color"];
        self.body[i] = mDic;
    }
}
//蛇移动，每次刷新时会在这个方法里改变蛇的坐标，并计算与食物的碰撞和自身的碰撞
-(void)snakeMove{
    
    //设置蛇身
    for(NSInteger i=self.body.count-1;i>0;i--){
     NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:self.body[i]];
     NSString *bodyx = self.body[i-1][@"bodyx"];
     NSString *bodyy = self.body[i-1][@"bodyy"];
     [mDic setObject:bodyx forKey:@"bodyx"];
     [mDic setObject:bodyy forKey:@"bodyy"];
     self.body[i] = mDic;
    }
    //设置蛇头
     NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:self.body[0]];
    NSString *headx=mDic[@"bodyx"] ;
    NSString *heady=mDic[@"bodyy"];
    if(self.directionCode==0){//上
        heady = [NSString stringWithFormat:@"%d",[heady intValue]-1];
    }else if (self.directionCode==1){//下
        heady = [NSString stringWithFormat:@"%d",[heady intValue]+1];
    }else if (self.directionCode==2){//左
        headx = [NSString stringWithFormat:@"%d",[headx intValue]-1];
    }else if (self.directionCode==3){//右
        headx = [NSString stringWithFormat:@"%d",[headx intValue]+1];
    }
    [mDic setObject:headx forKey:@"bodyx"];
    [mDic setObject:heady forKey:@"bodyy"];
    self.body[0] = mDic;
    //判断是否吃到食物
    if([headx integerValue]==self.foodx&&[heady integerValue]==self.foody){
        [self.body addObject:@{@"bodyx":@"-1",@"bodyy":@"0",@"color":[UIColor blueColor]}];
        if(self.time>0.25){
            self.time-=0.05;
            [self start];
//            [self createTimer];
        }
        
        [self createFood];
    }
    //判断是否撞到边界
    if([headx integerValue]<0||[headx integerValue]>LINECOUNT-1||[heady intValue]<0||[heady intValue]>LINECOUNT-1){
//        [self reload];
        [self stop];
        [self gameOver];
        
        return;
        
    }
    //判断是否撞到自己
    
    [self createSnake];
}
//游戏结束
-(void)gameOver{
    UILabel *gameOver = [[UILabel alloc]init];
    gameOver.text = @"GAME OVER!";
    gameOver.textColor = [UIColor redColor];
    [gameOver sizeToFit];
    gameOver.center = CGPointMake(self.map.bounds.size.width/2, self.map.bounds.size.height/2);
    //由于每次重置时都会清空map上的控件，所以gameover的label只创建就行了，不用手动释放
    [self.map addSubview:gameOver];
}
//创建定时器
-(void)createTimer{
    [self start];
}
//开始和暂停按钮
-(void)createControlButtons{
    //开始按钮
    UIButton *startBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.map.frame), 0, (SCREENWIDTH-SCREENHEIGHT)/4, SCREENHEIGHT/3)];
    [startBtn setTitle:@"继续" forState:UIControlStateNormal];
    startBtn.backgroundColor = [UIColor orangeColor];
    [startBtn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    //暂停按钮
    UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(SCREENWIDTH-(SCREENWIDTH-SCREENHEIGHT)/4, 0, (SCREENWIDTH-SCREENHEIGHT)/4, SCREENHEIGHT/3)];
    [stopBtn setTitle:@"暂停" forState:UIControlStateNormal];
    stopBtn.backgroundColor = [UIColor grayColor];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
}
//继续,这里创建定时器之前先销毁旧的计时器可以保证始终只有一个计时器在工作
-(void)start{
    //如果不先销毁定时器，不断点击继续按钮会创建很多个定时器，会出现蛇跑很快的bug，
 [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:self.time repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self snakeMove];
    }];
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSDefaultRunLoopMode];
}
//暂停
-(void)stop{
    [self.timer invalidate];
    
}
//下面是创建各种按钮，就不多说了
//上下左右按键
-(void)createDirectionButtons{
//    float btnW = (SCREENWIDTH-SCREENHEIGHT)/2;
    //左边的方向键view
    UIView *leftDirectionView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREENHEIGHT/3, (SCREENWIDTH-SCREENHEIGHT)/2, 2*SCREENHEIGHT/3)];
    [self.view addSubview:leftDirectionView];
    //右边的方向键view
    UIView *rightDirectionView = [[UIView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.map.frame), SCREENHEIGHT/3, (SCREENWIDTH-SCREENHEIGHT)/2, 2*SCREENHEIGHT/3)];
    [self.view addSubview:rightDirectionView];
    
    float btnH = 2*SCREENHEIGHT/9;
    for (int i=0; i<4; i++) {
        NSString *title;
        float x;
        float y;
        float w;
        UIColor *backColor;
    switch (i) {
        case 0:
            x = 0;
            y = 0;
            w = (SCREENWIDTH-SCREENHEIGHT)/2;
            title = @"上";
            backColor = [UIColor redColor];
            break;
        case 1:
            x = 0;
            y = 2*btnH;
            w = (SCREENWIDTH-SCREENHEIGHT)/2;
            title = @"下";
            backColor = [UIColor greenColor];
            break;
        case 2:
            x = 0;
            y = btnH;
            w = (SCREENWIDTH-SCREENHEIGHT)/4;
            title = @"左";
            backColor = [UIColor grayColor];
            break;
        default:
            x= (SCREENWIDTH-SCREENHEIGHT)/4;
            y=btnH;
            w = (SCREENWIDTH-SCREENHEIGHT)/4;
            title=@"右";
            backColor = [UIColor orangeColor];
            break;
        }
    //左边的按钮
    UIButton*btnLeft = [[UIButton alloc]initWithFrame:CGRectMake(x, y, w, btnH)];
    btnLeft.tag = i;
    [btnLeft setBackgroundColor:backColor];
    [btnLeft setTitle:title forState:UIControlStateNormal];
    [btnLeft addTarget:self action:@selector(directionChanged:) forControlEvents:UIControlEventTouchUpInside];
    //右边的按钮
    UIButton*btnRight = [[UIButton alloc]initWithFrame:CGRectMake(x, y, w, btnH)];
    btnRight.tag = i;
    [btnRight setBackgroundColor:backColor];
    [btnRight setTitle:title forState:UIControlStateNormal];
    [btnRight addTarget:self action:@selector(directionChanged:) forControlEvents:UIControlEventTouchUpInside];
    
    [leftDirectionView addSubview:btnLeft];
    [rightDirectionView addSubview:btnRight];
//    [self.view addSubview:btn];
    }
}
-(void)directionChanged:(UIButton*)btn{
    self.directionCode = btn.tag;
   // NSLog(@"%zd",btn.tag);
}
@end
