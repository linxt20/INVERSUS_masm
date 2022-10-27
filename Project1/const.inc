WNDCLASS STRUCT
	style				DWORD ?
	lpfnWndProc			DWORD ?
	cbClsExtra			DWORD ?
	cbWndExtra			DWORD ?
	hInstance			DWORD ?
	hIcon				DWORD ?
	hCursor				DWORD ?
	hbrBackground		DWORD ?
	lpszMenuName		DWORD ?
	lpszClassName		DWORD ?
WNDCLASS ENDS

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
	color				WORD ? ;1代表黑方射出的子弹（黑色），2代表白方，0代表不合法子弹
	heading				WORD ? ;子弹的朝向，1代表上，2代表下，3代表左，4代表右
BULLET ENDS


MAIN_WINDOW_STYLE = WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU \
+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME

; 函数引入，用于后面翻译键盘输入为字符码
TranslateMessage		PROTO STDCALL :DWORD
SetTimer				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
KillTimer				PROTO STDCALL :DWORD,:DWORD

GetDC					PROTO STDCALL :DWORD
GetStockObject			PROTO STDCALL :DWORD
ReleaseDC				PROTO STDCALL :DWORD,:DWORD
LoadImageA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
BeginPaint				PROTO STDCALL :DWORD,:DWORD
EndPaint				PROTO STDCALL :DWORD,:DWORD

CreateCompatibleDC		PROTO STDCALL: DWORD
CreateCompatibleBitmap	PROTO STDCALL :DWORD,:DWORD,:DWORD
SelectObject			PROTO STDCALL :DWORD,:DWORD
BitBlt					PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SetBkColor				PROTO STDCALL :DWORD,:DWORD
Rectangle				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
TextOutA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
CreateFontA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

PaintProc				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
emitBullet				PROTO STDCALL :WORD,:WORD,:WORD,:WORD

BLACK_BRUSH				EQU		4

WINDOW_WIDTH			EQU		640
WINDOW_HEIGHT			EQU		480

;固定参数，用于后面识别键盘按下与抬起
WM_PAINT				EQU		00000000fh
WM_KEYDOWN				EQU		000000100h
WM_KEYUP				EQU		000000101h

;==================== DATA =======================
.data

ErrorTitle				BYTE	"Error",0
youWinMsg				BYTE	"You Win!",0

WindowName				BYTE	"INVERSUS ASM",0
className				BYTE	"ASMWin",0

startText				BYTE	"start",0
helpText				BYTE	"help",0
exitText				BYTE	"exit",0
PVPText					BYTE	"P V P",0
PVEText					BYTE	"P V E",0
BackText				BYTE	"<-back",0

IDB_PNG1_PATH			BYTE	"..\Project1\image\black.jpg",0
IDB_PNG2_PATH			BYTE	"..\Project1\image\white.jpg",0
IDR_BG1_PATH			BYTE	"..\Project1\image\background.jpg",0
IDR_HELP_PATH			BYTE	"..\Project1\image\help.jpg",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg						MSGStruct <>
winRect					RECT <>
hMainWnd				DWORD ?
hInstance				DWORD ?
whitePicBitmap			DWORD ?
blackPicBitmap			DWORD ? 
bgPicBitmap				DWORD ?
helpPicBitmap			DWORD ?
hbitmap					DWORD ?
hdc						DWORD ?
holdbr					DWORD ?
holdft					DWORD ?
ps						PAINTSTRUCT	<>
hdcMem					DWORD ?
hdcMem2					DWORD ?

WhichMenu				DWORD 0			; 哪个界面，0表示开始，1表示选择游戏模式，2表示正在游戏，3表示游戏结束，4代表帮助界面
SelectMenu				DWORD 0			; 正在选择的菜单项

blackblock				WORD 164,164,23,1 ;第四个参数是朝向（heading），指示子弹发射的方向
whiteblock				WORD 452,292,23,1

;地图数组，20*15，0代表该格为空，1代表黑格，2代表白格
map		WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
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

;子弹数组，储存地图中的每颗子弹，在计时器中令所有子弹向指定方向移动一段距离
bullets					BULLET 10 DUP(< -1,-1,0,0 >)  
;假定地图中同时最多有10颗子弹，采取队列的思想，每次从currentBullet插入，并令currentBullets加一（并模10）
currentBullet			WORD 0