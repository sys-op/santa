program santa2;

uses
  Windows,
  Messages,
  Graphics,
  MMSystem;

{$R *.res}
{$R data.res}

const SnowCount = 1000;
    SnowPortion = 50;
      G         = 9.8;

type
  TSnow = packed record
    X : Integer;
    Y : Integer;
    C : TColor;
    D : Cardinal;
  end;

var hwd         : THandle;
  x,y,w,h       : Integer;
  rect          : TRect;
//  msg           : tagMSG;
  wcl           : TWndClass;
  clName        : PChar;
  bmp           : TBitmap;
  rgn           : HRGN;
  _hdc          : HDC;
//  hd            : HDC;
  snow          : array of TSnow;

  isshow        : Boolean;

  ProcessID     : Integer;
  ProcessHandle : THandle;
  ThreadHandle  : THandle;

  CurPortion    : Integer;
  Scale         : Double;
  reinitTime    : Cardinal;

procedure InitSnow;
var i: Integer;
begin
  Randomize;
  bmp.Dormant;
  bmp.FreeImage;
  bmp.LoadFromResourceID(hInstance,1);
  if Length(snow)=0 then SetLength(snow,SnowCount);
  CurPortion := Low(snow);
  for i:=Low(snow) to High(snow) do begin
    snow[i].X := 1+Random(w-1);//i * w div SnowPortion;
    snow[i].Y := Random(h div 2);
    snow[i].C := clWhite; //
    snow[i].D := GetTickCount
    //if i<SnowPortion then
    //else
    // snow[i].D := 0;
    //  snow[i].Y := 0;//Random(5);
  end;
  reinitTime := GetTickCount;
end;

procedure FinalSnow;
begin
  SetLength(snow,0);
end;

procedure ShowOneSnow(h,x,y,cl : Cardinal);
begin
{
    SetPixel(h, x,   y,    cl);
    SetPixel(h, x+1, y+1,  cl);
    SetPixel(h, x+1, y-1,  cl);
    SetPixel(h, x-1, y+1,  cl);
    SetPixel(h, x-1, y-1,  cl);
}

    SetPixel(h, x,   y,    cl);
    SetPixel(h, x,   y+1,  cl);
    SetPixel(h, x,   y-1,  cl);
    SetPixel(h, x-1, y,    cl);
    SetPixel(h, x+1, y,    cl);
end;

procedure PaintSnowOnPicture(ind : Integer);
begin
  ShowOneSnow(bmp.Canvas.Handle,snow[ind].X,snow[ind].Y,snow[ind].C);
end;


procedure SwapSnow(ind1, ind2 : Integer);
var tempSnow : TSnow;
begin
  if ind1=ind2 then Exit;

  tempSnow.X    := snow[ind1].X;
  tempSnow.Y    := snow[ind1].Y;
  tempSnow.C    := snow[ind1].C;
  tempSnow.D    := snow[ind1].D;

  snow[ind1].X  := snow[ind2].X;
  snow[ind1].Y  := snow[ind2].Y;
  snow[ind1].C  := snow[ind2].C;
  snow[ind1].D  := snow[ind2].D;

  snow[ind2].X  := tempSnow.X;
  snow[ind2].Y  := tempSnow.Y;
  snow[ind2].C  := tempSnow.C;
  snow[ind2].D  := tempSnow.D;
end;

function IsSnowBelow(CX,CY: Integer): Boolean;
var i,j: Integer;
begin
  Result := False;
  i := Low(snow);
  j := CurPortion;
  if j>High(snow) then j:=High(snow);
  while not Result and (i<j) do begin
    Result := (snow[i].X=CX) and (snow[i].Y-CY=1);
    Inc(i);
  end;
end;

procedure ShowSnow;
var i: Integer;
//   cl: TColor;
    t: Cardinal;
   td: Double;
   nextY: Integer;
//   ps: TPaintStruct;
begin
//  cl:=clWhite;
//  for i:=Low(snow) to High(snow) do begin
  i:=CurPortion;
  while ((i<=High(snow)) and (i<=(CurPortion+SnowPortion))) do begin

    ShowOneSnow(_hdc,snow[i].X, snow[i].Y, snow[i].C {cl});

    t := GetTickCount;
    td := (t-snow[i].D) / 1000;

    if (td>0.1) then begin

      nextY := snow[i].Y+Trunc((G*td*td/2)){;///Scale);//}-(Random(2));
      if ((nextY>=h) or (IsSnowBelow(snow[i].X,snow[i].Y))) then begin
        //snow[i].Y := Random(4) mod h
        PaintSnowOnPicture(i);
        SwapSnow(i,CurPortion);
        Inc(CurPortion);
        if CurPortion>High(snow) then
          reinitTime := GetTickCount
        else
          snow[CurPortion].D := t;
      end
      else begin
        snow[i].Y := nextY mod h;
        snow[i].X := abs(snow[i].X+(1-2*Random(2))*Random(10)) mod w;
      end;
      //InvalidateRect(hwd,@rect,True);
      //RedrawWindow(0,nil,0,RDW_INVALIDATE or RDW_UPDATENOW {or RDW_ALLCHILDREN});
    end;
    Inc(i);
  end;

//  for i:=Low(snow) to CurPortion-1 do begin
//    ShowOneSnow(_hdc,snow[i].X, snow[i].Y, snow[i].C {cl});
//  end;

end;

procedure ReleaseWave(ResName: PChar);
begin
  PlaySound(nil, 0, 0);
end;

procedure RetrieveWave(ResName: PChar);
var
  hResource: THandle;
  pData: Pointer;
begin
  ReleaseWave(ResName);
  hResource:=LoadResource( hInstance, FindResource(hInstance, ResName, 'WAVE'));
  try
    pData := LockResource(hResource);
    if pData <> nil then begin
      PlaySound(ResName, 0, SND_RESOURCE or SND_ASYNC or SND_LOOP);
      //PostMessage(hwd, WM_ACTIVATE, 0, 0);
    end;
  finally
    FreeResource(hResource);
  end;
//  PostMessage(hwd, WM_LBUTTONDOWN, MK_LBUTTON, 0);
end;

procedure ProcessKeyPressing(iMsg: integer; wParam: WPARAM; lParam: LPARAM);
begin
  case iMsg of
    WM_KEYUP:
    begin
      case wParam of
        VK_F4           : if GetKeyState(VK_MENU) < 0 then PostQuitMessage(0);
        VK_ESCAPE       : PostQuitMessage(0);
        Ord('1')        : RetrieveWave('#2');
        Ord('0')        : ReleaseWave('#2');
      end;
    end;
  end;
end;

procedure WindowPaint;
begin
  if not isshow then Exit;
  BitBlt(_hdc,0,0,w,h,bmp.Canvas.Handle,0,0,SRCCOPY);
  if (CurPortion > High(snow)) and (GetTickCount - reinitTime > 1000) then
    InitSnow;
  ShowSnow;
end;

procedure WindowResize;
begin
  if not isshow then Exit;
  GetWindowRect(hwd,rect);
  x := rect.Left;
  y := rect.Top;
  RedrawWindow(0,nil,0,RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN);
end;

function BitmapToRegion(Bitmap: TBitmap; TransColor: TColor): HRGN;
var
  X, Y: Integer;
  XStart: Integer;
begin
  Result := 0;
  with Bitmap do
    for Y := 0 to Height - 1 do
    begin
      X := 0;
      while X < Width do
      begin
        // Пропускаем прозрачные точки
        while (X < Width) and (Canvas.Pixels[X, Y] = TransColor) do
          Inc(X);
        if X >= Width then
          Break;
        XStart := X;
        // Пропускаем непрозрачные точки
        while (X < Width) and (Canvas.Pixels[X, Y] <> TransColor) do
          Inc(X);
        if Result = 0 then
          Result := CreateRectRgn(XStart, Y, X, Y + 1)
        else
          CombineRgn(Result, Result,
            CreateRectRgn(XStart, Y, X, Y + 1), RGN_OR);
      end;
    end;
end;

procedure WindowFunc(hMainWnd: HWND; iMsg: integer; wParam: WPARAM; lParam: LPARAM); stdcall;
Begin
case iMsg of
    WM_KEYUP,
    WM_KEYDOWN          : ProcessKeyPressing(iMsg,wParam,lParam);
    WM_DESTROY          : PostQuitMessage(0);
    WM_LBUTTONDOWN      : PostMessage(hMainWnd, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
    WM_PAINT            : WindowPaint;
    WM_MOVE             : WindowResize;
//    WM_ACTIVATE         : if LoWord(wParam)=WA_INACTIVE then begin
//                            SetActiveWindow(hMainWnd);
//                            PostMessage(hMainWnd, WM_ACTIVATE, (WA_ACTIVE)+HiWord(wParam), lParam);
//                            SetWindowPos(hwd,HWND_TOPMOST,x,y,w,h,SWP_SHOWWINDOW);
//                            UpdateWindow(hwd);
//                          end;
//    WM_MOVING           : WindowPaint;


    else
    DefWindowProc(hMainWnd, iMsg, wParam, lParam);
    end;
End;

function KeepRunning: Boolean;
var
  Msg: TMsg;
begin
  Result := True;
  if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then begin
    if (Msg.Message = WM_QUIT) then Result := False;
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

function OnPauseSleep: Boolean;
begin
  Sleep(50);
  Result := True;//((GetTickCount mod 100) < 100);
end;


begin
  isshow:= False;

  bmp := Graphics.TBitmap.Create;
  bmp.LoadFromResourceID(hInstance,1);
//  bmp.LoadFromFile('images2.bmp');

  GetClientRect(GetDesktopWindow(),rect);
  w := bmp.Width;
  h := bmp.Height;
  x := (rect.Right - w) div 2;
  y := (rect.Bottom - h) div 2;
  clName := 'MV_Santa_Class';

  wcl.hInstance := hInstance;
  wcl.lpszClassName := clName;
  wcl.lpfnWndProc := @WindowFunc;
  wcl.style := 0;
  wcl.hIcon := LoadIcon(0, IDI_ASTERISK);
  wcl.hCursor := LoadCursor(0,IDC_ARROW);
  wcl.lpszMenuName := nil;
  wcl.cbClsExtra := 0;
  wcl.cbWndExtra := 0;
  wcl.hbrBackground := COLOR_WINDOW;
  RegisterClass(wcl);

  hwd := CreateWindow(clName,'santa',WS_POPUP,x,y,w,h,HWND_DESKTOP,0,hInstance,nil);

  rgn := BitmapToRegion(bmp,bmp.Canvas.Pixels[0,0]);
  SetWindowRgn(hwd,rgn, True);
  DeleteObject(rgn);

  InitSnow;

  _hdc := GetDC(hwd);
  Scale := GetDeviceCaps(_hdc, LOGPIXELSY) * 100 / 2.54;
//  hd := GetDC(0);

  SetWindowPos(hwd,HWND_TOPMOST,x,y,w,h,SWP_SHOWWINDOW);
  UpdateWindow(hwd);

  isshow := True;

  //RetrieveWave('#2');

  ProcessID := GetCurrentProcessID;
  ProcessHandle := OpenProcess(PROCESS_SET_INFORMATION,false,ProcessID);
  SetPriorityClass(ProcessHandle, IDLE_PRIORITY_CLASS);
  ThreadHandle := GetCurrentThread;
  SetThreadPriority(ThreadHandle, THREAD_PRIORITY_IDLE);

{
  while GetMessage(msg,0,0,0) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
}
  while (KeepRunning and OnPauseSleep) do begin
  end;

  FinalSnow;
  bmp.Free;
//  ReleaseDC(hwd, hd);
  ReleaseDC(hwd, _hdc);
  InvalidateRect(hwd,@rect,True);
  DestroyWindow(hwd);
  RedrawWindow(0,nil,0,RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN);
end.

