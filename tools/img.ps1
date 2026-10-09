# Image helper for the Healing Spaces site (no Python on this PC; uses WPF/WIC, which also reads .webp)
# Usage: . .\img.ps1 ; Resize-Img src dst maxWidth [-Enhance] [-Quality 82]
Add-Type -AssemblyName PresentationCore, WindowsBase
Add-Type -ReferencedAssemblies PresentationCore, WindowsBase, System.Xaml -TypeDefinition @"
using System; using System.IO; using System.Windows; using System.Windows.Media; using System.Windows.Media.Imaging;
public static class Img {
  static BitmapSource Load(string p){ var b=new BitmapImage(); b.BeginInit(); b.CacheOption=BitmapCacheOption.OnLoad; b.UriSource=new Uri(p); b.EndInit();
    return new FormatConvertedBitmap(b, PixelFormats.Bgra32, null, 0); }
  static BitmapSource Scale(BitmapSource s,int maxW){ if(s.PixelWidth<=maxW) return s; double k=(double)maxW/s.PixelWidth;
    var t=new TransformedBitmap(s,new ScaleTransform(k,k)); return new FormatConvertedBitmap(t,PixelFormats.Bgra32,null,0); }
  static byte[] Px(BitmapSource s,out int st){ st=s.PixelWidth*4; var a=new byte[st*s.PixelHeight]; s.CopyPixels(a,st,0); return a; }
  static BitmapSource Make(BitmapSource s,byte[] a,int st){ return BitmapSource.Create(s.PixelWidth,s.PixelHeight,96,96,PixelFormats.Bgra32,null,a,st); }
  static void SaveJpg(BitmapSource s,string o,int q){ var e=new JpegBitmapEncoder(); e.QualityLevel=q; e.Frames.Add(BitmapFrame.Create(new FormatConvertedBitmap(s,PixelFormats.Bgr24,null,0))); using(var f=File.Create(o)) e.Save(f); }
  static void SavePng(BitmapSource s,string o){ var e=new PngBitmapEncoder(); e.Frames.Add(BitmapFrame.Create(s)); using(var f=File.Create(o)) e.Save(f); }
  // gentle "best light": lift shadows, soft S-curve, a touch of warmth and saturation
  static double Curve(double v,double lift,double contrast){ v=v+lift*(1-v)*(1-v)*v*4; double c=v-0.5; return 0.5+c*(1+contrast)-contrast*4*c*c*c; }
  public static void Resize(string src,string dst,int maxW,bool enhance,int q,double warm,double lift,double contrast,double sat){
    var s=Scale(Load(src),maxW); int st; var a=Px(s,out st);
    if(enhance){ for(int i=0;i<a.Length;i+=4){ double b=a[i]/255.0,g=a[i+1]/255.0,r=a[i+2]/255.0;
        r=Curve(r,lift,contrast); g=Curve(g,lift,contrast); b=Curve(b,lift,contrast);
        r*=1+warm; g*=1+warm*0.35; b*=1-warm*0.6;
        double l=0.299*r+0.587*g+0.114*b; r=l+(r-l)*(1+sat); g=l+(g-l)*(1+sat); b=l+(b-l)*(1+sat);
        a[i]=(byte)Math.Max(0,Math.Min(255,Math.Round(b*255))); a[i+1]=(byte)Math.Max(0,Math.Min(255,Math.Round(g*255))); a[i+2]=(byte)Math.Max(0,Math.Min(255,Math.Round(r*255))); } s=Make(s,a,st); }
    if(dst.EndsWith(".png")) SavePng(s,dst); else SaveJpg(s,dst,q); }
  // crop a region and make near-white pixels transparent (for the logo symbol)
  public static void CropKey(string src,string dst,int x,int y,int w,int h,int scale){
    var s=new CroppedBitmap(Load(src),new Int32Rect(x,y,w,h)); BitmapSource c=new FormatConvertedBitmap(s,PixelFormats.Bgra32,null,0);
    if(scale!=1){ c=new FormatConvertedBitmap(new TransformedBitmap(c,new ScaleTransform(scale,scale)),PixelFormats.Bgra32,null,0); }
    int st; var a=Px(c,out st);
    for(int i=0;i<a.Length;i+=4){ int mn=Math.Min(a[i],Math.Min(a[i+1],a[i+2])); // white -> 0 alpha, ink -> full
      double alpha=Math.Max(0,Math.Min(1,(235-mn)/120.0)); a[i+3]=(byte)Math.Round(alpha*255); }
    SavePng(Make(c,a,st),dst); }
}
"@
function Resize-Img($src,$dst,[int]$maxW,[switch]$Enhance,[int]$Quality=82,[double]$Warm=0.04,[double]$Lift=0.06,[double]$Contrast=0.08,[double]$Sat=0.08){
  [Img]::Resize((Resolve-Path $src).Path,$dst,$maxW,[bool]$Enhance,$Quality,$Warm,$Lift,$Contrast,$Sat)
  "{0}  {1:N0} KB" -f (Split-Path $dst -Leaf),((Get-Item $dst).Length/1KB)
}
