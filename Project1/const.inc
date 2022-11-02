;消息结构数组
MSGStruct STRUCT
	msgWnd				DWORD ?
	msgMessage			DWORD ?
	msgWparam			DWORD ?
	msgLparam			DWORD ?
	msgTime				DWORD ?
	msgPt				POINT <>
MSGStruct ENDS

;子弹数组定义
BULLET STRUCT
	xCoor				SWORD ? ;单位：像素
	yCoor				SWORD ? ;单位：像素
	color				WORD  ? ;1代表黑方射出的子弹（黑色），2代表白方，0代表不合法子弹
	heading				WORD  ? ;子弹的朝向，1代表上，2代表下，3代表左，4代表右
BULLET ENDS


; 特有变量声明区域

; 窗口长宽
WINDOW_WIDTH			EQU		640
WINDOW_HEIGHT			EQU		480

; 消息固定参数
WM_PAINT				EQU		00000000fh
WM_KEYDOWN				EQU		000000100h
WM_KEYUP				EQU		000000101h


; 函数声明区域
; 消息部分
; 消息转换用于后面翻译键盘输入为字符码
TranslateMessage		PROTO STDCALL :DWORD

; 定时器部分
; 定时器设置
SetTimer				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
; 定时器删除
KillTimer				PROTO STDCALL :DWORD,:DWORD

; 绘图部分
; 获取程序显示DC句柄
GetDC					PROTO STDCALL :DWORD
; 释放DC窗口句柄
ReleaseDC				PROTO STDCALL :DWORD,:DWORD
; 图片加载函数 
LoadImageA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 开始绘画函数
BeginPaint				PROTO STDCALL :DWORD,:DWORD
; 结束绘画函数
EndPaint				PROTO STDCALL :DWORD,:DWORD
; 创造与指定DC兼容的存储DC
CreateCompatibleDC		PROTO STDCALL: DWORD
; 创造与指定DC兼容的位图句柄
CreateCompatibleBitmap	PROTO STDCALL :DWORD,:DWORD,:DWORD
; 用选定的DC填充目标DC
SelectObject			PROTO STDCALL :DWORD,:DWORD
; 将指定的DC链接到目标DC的某一个区域上，是一个显示图片的函数
BitBlt					PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 设置背景颜色
SetBkColor				PROTO STDCALL :DWORD,:DWORD
; 将字符串链接到目标DC的某一个区域上，是一个显示数字的函数
TextOutA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 创建指定的字体
CreateFontA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 运行windows命令函数
ShellExecuteA			PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 播放音频文件函数
PlaySound				PROTO STDCALL :DWORD,:DWORD,:DWORD


; 自定义函数声明区域
PaintProc				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
emitBullet				PROTO STDCALL :WORD,:WORD,:WORD,:WORD
;==================== DATA =======================
.data

; 字符串定义区域
WindowName				BYTE	"INVERSUS ASM",0		; 窗口名
className				BYTE	"ASMWin",0				; 窗口类名

ErrorTitle				BYTE	"Error",0				; 错误警告弹窗标题

P1WinMsg				BYTE	"P1 Win",0				; P1胜利提示   
P2WinMsg				BYTE	"P2 Win",0				; P2胜利提示   
endbacktip				BYTE	"press r to comeback",0	; 结束页面提示语言

startText				BYTE	"start",0				; 开始游戏标签     
helpText				BYTE	"help",0				; 控制帮助文档标签
customText				BYTE	"custom",0				; 个性化定义颜色标签
exitText				BYTE	"exit",0				; 退出游戏标签
PVPText					BYTE	"P V P",0				; 双人小游戏模式标签
PVEText					BYTE	"P V E",0				; 单机模式标签     unused
BackText				BYTE	"<-back",0				; 返回上一级目录标签
arrowText				BYTE	"->",0					; 指示地图选择标签
pauseText				BYTE	"Pausing, press Esc to continue",0   ; 暂停标签
bgChooseText			BYTE	"background",0			; 背景选择标签
p1ChooseText			BYTE	"    p1    ",0			; p1选择标签
p2ChooseText			BYTE	"    p2    ",0			; p2选择标签

helptext_title1			byte	"game rule show",0
helptext_title2			byte	"game control show",0
helptext_hang1			byte	"INVERSUS is a shooting game, in the game, you need to",0  ; 53
helptext_hang2			byte	"play for one of the black and white, and compared with",0  ;54
helptext_hang3			byte	"the other party. The victory of the game goal is simple",0   ;55
helptext_hang4			byte	"which is only to hit each other.",0     ;32
helptext_hang5			byte	"Please note that the map is also divided into black and",0    ;55
helptext_hang6			byte	"white two colors, you can only move in the area of the",0  ;54
helptext_hang7			byte	"contrary to their own color, you can shoot to change",0  ;52
helptext_hang8			byte	"the path of regional color so that you can make your",0       ;52
helptext_hang9			byte	"role in this area.",0   ;18
helptext_hang10_1		byte	"play 1: black block move by",0  ;27
helptext_hang10_2		byte	"w",0
helptext_hang10_3		byte	"s",0
helptext_hang10_4		byte	"a",0
helptext_hang10_5		byte	"d",0
helptext_hang10_6		byte	"shoot by",0  ; 8
helptext_hang10_7		byte	"space",0  ;5
helptext_hang11_1		byte	"play 2: white block move by",0  ;27
helptext_hang11_2		byte	"up",0    ; 2
helptext_hang11_3		byte	"down",0  ; 4
helptext_hang11_4		byte	"<-",0   ;  2
helptext_hang11_5		byte	"->",0   ; 2
helptext_hang11_6		byte	"shoot by",0  ; 8
helptext_hang11_7		byte	"enter",0  ;5
helptext_hang12_1       byte     "In custom menu,selcet background by",0 ;35
helptext_hang12_2		byte	"I",0    ; 1
helptext_hang12_3		byte	"J",0  ; 1
helptext_hang12_4		byte	"K",0   ;  1
helptext_hang12_5		byte	"L",0   ; 1
helptext_hang12_6       byte    "Select p1,p2",0 ;18
helptext_hang13		byte	"color by theirs movekey,use enter or space to confirm",0  ; 53
helptext_hang14     BYTE   "-------------press enter or space to comeback-------------",0 ;54
 

IDR_MAP1_PATH			BYTE	"..\Project1\image\1.jpg",0          ; 地图1图片路径
IDR_MAP2_PATH			BYTE	"..\Project1\image\2.jpg",0          ; 地图2图片路径
IDR_MAP3_PATH			BYTE	"..\Project1\image\3.jpg",0          ; 地图3图片路径

shoot_Mp3_PATH			BYTE	"..\Project1\mp3\shoot.wav"          ; 射击音频文件路径


; 结构变量定义区域
; Define the Application's Window class structure.
MainWin					WNDCLASS	<NULL,WinProc,NULL,NULL,NULL,NULL,NULL, COLOR_WINDOW,NULL,className>
; 消息结构变量定义
msg						MSGStruct	<>
; 画笔结构变量定义
ps						PAINTSTRUCT	<>

; 普通变量定义区域
; 句柄变量
hMainWnd				DWORD ? ; 总窗口句柄
hInstance				DWORD ? ; 用于创建调用进程的文件的句柄
hdc						DWORD ? ; 程序窗口的句柄
hdcMempage				DWORD ? ; 布局页面显示句柄
hdcMemwhite				DWORD ? ; 白色块显示句柄
hdcMemblack				DWORD ? ; 黑色块显示句柄
hdcMembg				DWORD ? ; 背景块显示句柄
hdcMemhelp				DWORD ? ; 帮助图显示句柄
hdcMemMap1				DWORD ? ; 地图1图片显示句柄
hdcMemMap2				DWORD ? ; 地图2图片显示句柄
hdcMemMap3				DWORD ? ; 地图3图片显示句柄
hdcMemColors			DWORD 20 DUP(?) ; 20种颜色显示句柄

; 菜单选项变量
WhichMenu				DWORD 0 ; 哪个界面，0表示开始，1表示选择游戏模式，2表示正在游戏，3表示游戏结束，4代表帮助界面，5代表选关界面，6代表自定义界面
SelectMenu				SDWORD 0 ; 正在选择的菜单项 0表示第一项
SelectMenu2				SDWORD 0 ; 用来在自定义界面给p2提供光标移动选择
SelectMenu3				SDWORD 0 ; 用来在自定义界面对背景进行选择

; 方块状态变量  前两位是位置，第三位是大小，第四位是朝向(heading)，指示子弹发射的方向，第五位为剩余子弹数（每人上限为4）
;第六位是冷却（子弹恢复）计数器，当达到100时（也即，子弹恢复时间为3秒）清零，并增加一发子弹
blackblock				WORD 164,164,23,1,4,0
whiteblock				WORD 452,292,23,1,4,0

; 每一轮黑白块的初始位置 第一个数是横向的刻度，第二个数是纵向的刻度
black_initpos			WORD 164,164
white_initpos			WORD 452,292

; 颜色变量
Colors					DWORD 00000000h,00FFFFFFh,00CCA700h,00FF0000h,0000FF00h
						DWORD 00FF00FFh,0000FFFFh,00FFFF00h,000000FFh,009900FFh
						DWORD 00674EA7h,00777777h,00777700h,008E7CC3h,00D1EEEEh
						DWORD 008E388Eh,00D9D9D9h,007F6000h,00274E13h,00EAD1DCh

; 字体变量
font_50					DWORD ?  ; 高度为50像素的字体
font_40					DWORD ?  ; 高度为40像素的字体
font_20					DWORD ?  ; 高度为20像素的字体

; 每一轮地图数组，20*15，0代表该格为空，1代表黑格，2代表白格
roundone_map			WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
						WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,2,2,2,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,2,2,2,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,2,2,2,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,1,1,1,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,1,1,1,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,1,1,1,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
						WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
						WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

roundtwo_map			WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,2,2,0,0,2,2,2,2,2,1,1,1,1,1,0,0,1,1,0
						WORD 0,2,2,0,0,2,2,2,2,2,1,1,1,1,1,0,0,1,1,0
						WORD 0,2,2,2,2,2,2,0,0,0,0,0,0,1,1,1,1,1,1,0
						WORD 0,2,2,2,2,2,2,0,0,0,0,0,0,1,1,1,1,1,1,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,2,2,2,2,2,2,0,0,0,0,0,0,1,1,1,1,1,1,0
						WORD 0,2,2,2,2,2,2,0,0,0,0,0,0,1,1,1,1,1,1,0
						WORD 0,2,2,0,0,2,2,2,2,2,1,1,1,1,1,0,0,1,1,0
						WORD 0,2,2,0,0,2,2,2,2,2,1,1,1,1,1,0,0,1,1,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

roundthree_map			WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,2,0,0,0,0,0,0,0,2,1,0,0,0,0,0,0,0,1,0
						WORD 0,2,0,2,2,2,2,2,2,2,1,1,1,1,1,1,1,0,1,0
						WORD 0,2,0,2,0,2,0,0,0,0,0,0,0,0,1,0,1,0,1,0
						WORD 0,2,0,2,0,2,2,2,2,2,1,1,1,1,1,0,1,0,1,0
						WORD 0,2,0,2,0,2,0,0,0,2,1,0,0,0,1,0,1,0,1,0
						WORD 0,2,2,2,0,2,2,2,2,2,1,1,1,1,1,0,1,1,1,0
						WORD 0,2,0,2,0,2,0,0,0,2,1,0,0,0,1,0,1,0,1,0
						WORD 0,2,0,2,0,2,2,2,2,2,1,1,1,1,1,0,1,0,1,0
						WORD 0,2,0,2,0,2,0,0,0,0,0,0,0,0,1,0,1,0,1,0
						WORD 0,2,0,2,2,2,2,2,2,2,1,1,1,1,1,1,1,0,1,0
						WORD 0,2,0,0,0,0,0,0,0,2,1,0,0,0,0,0,0,0,1,0
						WORD 0,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,0
						WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; 游戏中使用的临时地图数组，主要拷贝地图数组的内容，使地图数组能够反复利用
map						WORD 300 DUP(?)

;子弹数组，储存地图中的每颗子弹，在计时器中令所有子弹向指定方向移动一段距离
bullets					BULLET 10 DUP(< -1,-1,0,0 >)  
;假定地图中同时最多有10颗子弹，采取队列的思想，每次从currentBullet插入，并令currentBullets加一（并模10）
currentBullet			WORD 0

; 状态变量
statusFlag				WORD 0 ;状态flag，0代表未胜利，游戏正常进行，1代表黑方胜利，2代表白方胜利，3代表暂停
attack_black            DWORD 1 ;
attack_white            DWORD 1;

; 按键是否按下的指示变量
UpKeyHold				DWORD 0 
DownKeyHold				DWORD 0
LeftKeyHold				DWORD 0
RightKeyHold			DWORD 0
WKeyHold				DWORD 0
SKeyHold				DWORD 0
AKeyHold				DWORD 0
DKeyHold				DWORD 0
SpaceKeyHold			DWORD 0
EnterKeyHold			DWORD 0