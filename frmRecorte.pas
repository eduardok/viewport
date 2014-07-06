unit frmRecorte;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ToolWin, Menus, StdCtrls, ExtCtrls; 

type
  Ponto = Record
    x,y : Real;
  end;
  Reta = Record
    p1,p2 : Ponto;
  end;

  TForm1 = class(TForm)
    GroupBox2: TGroupBox;
    Shape1: TShape;
    eEsquerda: TEdit;
    eLargura: TEdit;
    eSuperior: TEdit;
    eAltura: TEdit;
    udEsquerda: TUpDown;
    udLargura: TUpDown;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    udSuperior: TUpDown;
    udAltura: TUpDown;
    Panel1: TPanel;
    imgWindow: TImage;
    retWindow: TShape;
    Label11: TLabel;
    Panel2: TPanel;
    imgViewport: TImage;
    Panel3: TPanel;
    imgVisao: TImage;
    Label5: TLabel;
    Label6: TLabel;
    retVisao: TShape;
    Edit1: TEdit;
    Label7: TLabel;
    procedure Sair1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgWindowMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgWindowMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure udEsquerdaChanging(Sender: TObject;
      var AllowChange: Boolean);
    procedure udLarguraChanging(Sender: TObject; var AllowChange: Boolean);
    procedure udSuperiorChanging(Sender: TObject;
      var AllowChange: Boolean);
    procedure udAlturaChanging(Sender: TObject; var AllowChange: Boolean);
    procedure imgWindowMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    qt : Integer;  //quantidades de retas completas (p1 e p2)
    pri : boolean;
    retas : Array of Reta;
    { Private declarations }
    procedure DesenhaWindow;
    procedure DesenhaVisao;
    procedure DesenhaViewport;
    procedure AdicionaPonto(X,Y: Integer);
    function PontoWV(ponto : Ponto) : Ponto;
    function Recorta(reta : Reta) : Reta;
    function OndeEsta(ponto : Ponto) : Integer;
    function TrocaEmX(p : Ponto; winy : Real; m : Real) : Ponto;
    function TrocaEmY(p : Ponto; winx : Real; m : Real) : Ponto;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.Sair1Click(Sender: TObject);
begin
   close();
end;

procedure TForm1.FormCreate(Sender: TObject);
  var r : Real;
begin
   imgWindow.Canvas.Rectangle(0,0,imgWindow.width,imgWindow.height);
   imgVisao.Canvas.Rectangle(0,0,imgVisao.width,imgVisao.height);
   imgViewport.Canvas.Rectangle(0,0,imgViewport.width,imgViewport.height);
   DesenhaWindow;
   DesenhaVisao;
   DesenhaViewport;
   pri := true;
   //define maximos
   udEsquerda.Max := 100;
   udAltura.Max := 100;
   udLargura.Max := 100;
   udSuperior.Max := 100;

   //define tamanho inicial retangulo
   r := StrToFloat(eEsquerda.text);
   retWindow.Left := Round((imgWindow.Width/99)*r);
   retVisao.Left := Round((imgVisao.Width/99)*r);

   r := StrToFloat(eLargura.text);
   retWindow.Width := Round((imgWindow.Width/99)*r);
   retVisao.Width := Round((imgVisao.Width/99)*r)-1;

   r := StrToFloat(eSuperior.text);
   retWindow.Top := Round(((imgWindow.Top+imgWindow.Height)/99)*r);
   retVisao.Top := Round(((imgVisao.Top+imgVisao.Height)/99)*r)-6;

   r := StrToFloat(eAltura.text);
   retWindow.Height := Round((imgWindow.Height/99)*r);
   retVisao.Height := Round((imgVisao.Height/99)*r);
end;

{ Desenha a Window }
procedure TForm1.DesenhaWindow;
   var
      f1,f2 : Real;
      i,a : Integer;
begin
   f1 := imgWindow.Height / 10;
   f2 := imgWindow.Width / 10;
   imgWindow.Canvas.Pen.Color := clSilver;
   for i := 1 to 9 do
   begin
      //Linhas horizontais
      imgWindow.Canvas.MoveTo(0,Round(f1 * i));
      imgWindow.Canvas.LineTo(imgWindow.Width,Round(f1 * i));
      //Linhas verticais
      imgWindow.Canvas.MoveTo(Round(f2 * i),0);
      imgWindow.Canvas.LineTo(Round(f2 * i),imgWindow.Height);
   end;
   //Põe as coordenadas
   imgWindow.Canvas.TextOut(1,imgWindow.Height-15,'(0,0)');
   imgWindow.Canvas.TextOut(imgWindow.Width-47,1,'(100,100)');
   //[Re]Desenha linhas
   imgWindow.Canvas.Pen.Color := clBlack;
   if(qt>0) then begin
      for a:=0 to (qt-1) do begin
         imgWindow.Canvas.MoveTo(Round(retas[a].p1.x),Round(retas[a].p1.y));
         imgWindow.Canvas.LineTo(Round(retas[a].p2.x),Round(retas[a].p2.y));
      end;
   end;
end;

{ Desenha a Visão }
procedure TForm1.DesenhaVisao;
   var
      a : Integer;
      tmp : Reta;
begin
   imgVisao.Canvas.Rectangle(0,0,imgVisao.width,imgVisao.height);
   imgVisao.Canvas.Pen.Color := clSilver;
   imgVisao.Canvas.TextOut(1,imgVisao.Height-15,'(0,0)');
   imgVisao.Canvas.TextOut(imgVisao.Width-47,1,'(100,100)');
   imgVisao.Canvas.Pen.Color := clBlack;
   if(qt>0) then begin
      for a:=0 to (qt-1) do begin
         tmp := Recorta(retas[a]);
         if((tmp.p1.x >=0)) then begin
            imgVisao.Canvas.MoveTo(Round(tmp.p1.x-1),Round(tmp.p1.y-6));
            imgVisao.Canvas.LineTo(Round(tmp.p2.x-1),Round(tmp.p2.y-6));
         end;
      end;
   end;
end;

{ Desenha a Viewport }
procedure TForm1.DesenhaViewport;
   var
      a : Integer;
      tmp : Reta;
      p : Ponto;
begin
   imgViewport.Canvas.Rectangle(0,0,imgVisao.width,imgVisao.height);
   imgViewport.Canvas.Pen.Color := clBlack;
   if(qt>0) then begin
      for a:=0 to (qt-1) do begin
         tmp := Recorta(retas[a]);
         if((tmp.p1.x >=0)) then begin
            tmp.p1.x := tmp.p1.x;
            tmp.p2.x := tmp.p2.x;
            tmp.p1.y := tmp.p1.y;
            tmp.p2.y := tmp.p2.y;
            p := PontoWV(tmp.p1);
            imgViewport.Canvas.MoveTo(Round(p.x),Round(p.y-7));
            p := PontoWV(tmp.p2);
            imgViewport.Canvas.LineTo(Round(p.x),Round(p.y-7));
         end;
      end;
   end;
end;

procedure TForm1.imgWindowMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
end;

//Adiciona ponto na Reta
procedure TForm1.AdicionaPonto(X, Y: Integer);
  var p : Ponto;
begin
   p.x := X;
   p.y := Y;
   //Se for o primeiro ponto
   if(pri) then begin
      //Cria novo espaço para reta
      SetLength(retas,Length(retas)+1);
      retas[Length(retas)-1].p1 := p;
      pri := false;
      end
   else begin  //Senao preenche p2
      retas[Length(retas)-1].p2.x := X;
      retas[Length(retas)-1].p2.y := Y;
      pri := true;
      qt := qt+1;
   end;
end;

{ Converte de Window p/ Viewport }
function TForm1.PontoWV(ponto : Ponto) : Ponto;
begin
   ponto.x := round(imgViewport.Left+((ponto.x-retWindow.Left)*(imgViewport.Width+10 ))/retWindow.Width);
   ponto.y := round(imgViewport.Top +((ponto.y-retWindow.Top )*(imgViewport.Height+14))/retWindow.Height);
   Result := ponto;
end;

function TForm1.Recorta(reta: Reta): Reta;
   var
      kdp1,kdp2,qual : Integer;
      ok : boolean;
      m,d : Real;
      pt : Ponto;
begin
   ok := false;
   //   9=1001  |  8=1000  |  10=1010
   // ----------|----------|-----------
   //   1=0001  |  0=0000  |  2 =0010
   // ----------|----------|-----------
   //   5=0101  |  4=0100  |  6 =0110

   kdp1 := OndeEsta(reta.p1);
   kdp2 := OndeEsta(reta.p2);
   while(not ok) do begin
      //Aceitação trivial - os 2 dentro
      if( (kdp1 or kdp2)=0) then begin
         ok := true;
         end
      //Rejeição trivial - os 2 em cima/baixo/direita/esquerda
      else if(((kdp1 and kdp2)=1) or ((kdp1 and kdp2)=2) or ((kdp1 and kdp2)=4) or ((kdp1 and kdp2)=8) or (kdp1=kdp2)) then begin
         reta.p1.x := -1; //flag indicadora
         ok := true;
         end
      else begin
         qual := kdp1;
         pt := reta.p1;
         if(qual=0) then begin
            qual := kdp2;
            pt := reta.p2;
         end;
         d := (reta.p2.x - reta.p1.x);
         if(d<>0) then begin
            m := (reta.p2.y - reta.p1.y) / d;
            end
         else begin
            m := 0;
         end;

         //comeca casos nao triviais
         //Se esta acima
         if((qual and 8)=8) then begin
            pt := TrocaEmX(pt,retWindow.Top,m);
           end
         //Se esta abaixo
         else if((qual and 4)=4) then begin
            pt := TrocaEmX(pt,retWindow.Top+retWindow.Height-3,m);
           end
         //Se esta à direita
         else if((qual and 2)=2) then begin
            pt := TrocaEmY(pt,retWindow.Left+retWindow.Width-3,m);
           end
         //Se esta à esquerda
         else begin
            pt := TrocaEmY(pt,retWindow.Left,m);
         end;

         //usa novos X e Y calculados acima
         if(kdp1 <> 0) then begin //primeiro ponto foi cortado
            reta.p1.x := pt.x;
            reta.p1.y := pt.y;
            kdp1 := OndeEsta(reta.p1);
            end
         else begin //segundo ponto foi cortado
            reta.p2.x := pt.x;
            reta.p2.y := pt.y;
            kdp2 := OndeEsta(reta.p2);
         end;
      end;
   end;
   Result := reta;
end;

function TForm1.TrocaEmX(p : Ponto ; winy : Real; m : Real): Ponto;
begin
   //em testes ocorreram casos de m=0 entao tenho que verificar
   if(m<>0) then begin
      p.x := p.x + (winy - p.y) / m;
   end;
   p.y := winy;
   Result := p;
end;

function TForm1.TrocaEmY(p : Ponto; winx : Real; m : Real): Ponto;
begin
   p.y := p.y + (winx - p.x) * m;
   p.x := winx;
   Result := p;
end;

{ Algoritmo Cohen Sutherland }
function TForm1.OndeEsta(ponto: Ponto): Integer;
   var onde : Integer;
begin
   onde := 0; //0000 -> padrão dentro, senão irá definir abaixo

   //Verifica se ponto está acima ou abaixo
   if(ponto.y <= (retWindow.Top-imgWindow.Top)) then begin
      onde := onde or 8; //acima  ->  10xx
      end
   else if(ponto.y >= (retWindow.Top-imgWindow.Top+retWindow.Height-1)) then begin
      onde := onde or 4; //abaixo  ->  01xx
   end;
   //Verifica se o ponto está à direita ou à esquerda
   if((ponto.x) >= (retWindow.Left-imgWindow.Left+retWindow.Width-1)) then begin
      onde := onde or 2; //direita  -> xx10
      end
   else if ((ponto.x) <= retWindow.Left-imgWindow.Left) then begin
      onde := onde or 1; //esquerda  -> xx01
   end;
   Result := onde;
end;

procedure TForm1.imgWindowMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   //Adiciona ponto clicado à reta
   AdicionaPonto(x,y);
   //Mando redesenhar tudo
   DesenhaWindow;
   DesenhaVisao;
   DesenhaViewport;
end;

procedure TForm1.udEsquerdaChanging(Sender: TObject;
  var AllowChange: Boolean);
  var r : Real;
begin
   r := StrToFloat(eEsquerda.text);
   retWindow.Left := Round((imgWindow.Width/99)*r);
   retVisao.Left := Round((imgVisao.Width/99)*r);
   DesenhaWindow;
   DesenhaVisao;
   DesenhaViewport;
end;

procedure TForm1.udLarguraChanging(Sender: TObject;
  var AllowChange: Boolean);
  var r : Real;
begin
   r := StrToFloat(eLargura.text);
   retWindow.Width := Round((imgWindow.Width/99)*r);
   retVisao.Width := Round((imgVisao.Width/99)*r)-1;
   DesenhaWindow;
   DesenhaVisao;
   DesenhaViewport;
end;

procedure TForm1.udSuperiorChanging(Sender: TObject;
  var AllowChange: Boolean);
  var r : Real;
begin
   r := StrToFloat(eSuperior.text)+5;
   retWindow.Top := Round(((imgWindow.Top+imgWindow.Height)/99)*r);
   retVisao.Top := Round(((imgVisao.Top+imgVisao.Height)/99)*r)-4;
   DesenhaWindow;
   DesenhaVisao;
   DesenhaViewport;
end;

procedure TForm1.udAlturaChanging(Sender: TObject;
  var AllowChange: Boolean);
  var r : Real;
begin
   r := StrToFloat(eAltura.text);
   retWindow.Height := Round((imgWindow.Height/99)*r);
   retVisao.Height := Round((imgVisao.Height/99)*r);
   DesenhaWindow;
   DesenhaVisao;
   DesenhaViewport;
end;

procedure TForm1.imgWindowMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
  var
     p : Ponto;
begin
p.x := X;
p.y := Y;
Edit1.Text := IntToStr(OndeEsta(p));
end;

end.
