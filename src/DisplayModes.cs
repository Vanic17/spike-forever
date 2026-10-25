using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Web.Script.Serialization;
using System.Management;

// Temporary, supported Windows display modes. Never writes the registry.
internal static class DisplayModes {
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] struct Device {
  public int cb;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string name;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)] public string description;
  public int flags;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)] public string id;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)] public string key;
 }
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] struct Mode {
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string device;
  public short spec,driver,size,extra; public int fields,x,y,orientation,fixedOutput;
  public short color,duplex,yResolution,ttOption,collate;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string form;
  public short logPixels; public int bits,width,height,flags,hz,icmMethod,icmIntent,media,dither,reserved1,reserved2,panningWidth,panningHeight;
 }
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern bool EnumDisplayDevices(string device,int index,ref Device output,int flags);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern bool EnumDisplaySettings(string device,int index,ref Mode mode);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int ChangeDisplaySettingsEx(string device,ref Mode mode,IntPtr hwnd,int flags,IntPtr param);
 static Mode Empty(){var m=new Mode();m.size=(short)Marshal.SizeOf(typeof(Mode));return m;}
 static object Row(Mode m){return new {width=m.width,height=m.height,hz=m.hz};}
 static object NativeMode(string adapter,Mode current){
  try {
   var monitor=new Device();monitor.cb=Marshal.SizeOf(typeof(Device));
   if(!EnumDisplayDevices(adapter,0,ref monitor,0))return Row(current);
   string[] id=monitor.id.Split('\\');if(id.Length<2)return Row(current);
   var options=new EnumerationOptions();options.Timeout=TimeSpan.FromSeconds(2);
   using(var search=new ManagementObjectSearcher(new ManagementScope("root\\wmi"),new ObjectQuery("SELECT * FROM WmiMonitorListedSupportedSourceModes WHERE Active=True"),options))
   using(var result=search.Get()){
    foreach(ManagementObject item in result){
     if(Convert.ToString(item["InstanceName"]).IndexOf("\\"+id[1]+"\\",StringComparison.OrdinalIgnoreCase)<0)continue;
     var modes=(ManagementBaseObject[])item["MonitorSourceModes"];int preferred=Convert.ToInt32(item["PreferredMonitorSourceModeIndex"]);
     if(preferred<0 || preferred>=modes.Length)continue;
     int width=Convert.ToInt32(modes[preferred]["HorizontalActivePixels"]),height=Convert.ToInt32(modes[preferred]["VerticalActivePixels"]);
     if(width>=1024 && height>=600)return new {width=width,height=height,hz=current.hz};
    }
   }
  }catch{}
  return Row(current);
 }
 static int Main(string[] args){try {
  var json=new JavaScriptSerializer();
  if(args.Length==0 || args[0]=="--list"){
   var devices=new List<object>();
   for(int i=0;;i++){
    var d=new Device();d.cb=Marshal.SizeOf(typeof(Device));
    if(!EnumDisplayDevices(null,i,ref d,0))break;
    if((d.flags&1)==0)continue;
    var current=Empty();if(!EnumDisplaySettings(d.name,-1,ref current))continue;
    var modes=new List<object>();var seen=new HashSet<string>();
    for(int n=0;;n++){
     var m=Empty();if(!EnumDisplaySettings(d.name,n,ref m))break;
     if(m.bits<24 || m.width<1024 || m.height<600 || m.hz<24 || (m.flags&2)!=0)continue;
     string key=m.width+":"+m.height+":"+m.hz;
     if(seen.Add(key))modes.Add(Row(m));
    }
    devices.Add(new {device=d.name,name=d.description,x=current.x,y=current.y,current=Row(current),native=NativeMode(d.name,current),modes=modes});
   }
   Console.WriteLine(json.Serialize(devices));return 0;
  }
  if(args.Length!=5 || (args[0]!="--apply" && args[0]!="--test"))return 2;
  int width=int.Parse(args[2]),height=int.Parse(args[3]),hz=int.Parse(args[4]);
  // Refuse arbitrary or unsupported combinations, including disconnected devices.
  for(int n=0;;n++){
   var mode=Empty();if(!EnumDisplaySettings(args[1],n,ref mode))break;
   if(mode.width!=width || mode.height!=height || mode.hz!=hz || mode.bits<24 || (mode.flags&2)!=0)continue;
   mode.fields=0x80000|0x100000|0x400000;
   int result=ChangeDisplaySettingsEx(args[1],ref mode,IntPtr.Zero,args[0]=="--test"?2:4,IntPtr.Zero);
   Console.WriteLine(result);return result==0?0:3;
  }
  Console.WriteLine("Unsupported display mode");return 4;
 }catch(Exception e){Console.WriteLine(e.Message);return 1;}}
}
