using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class Launcher
{
    [STAThread]
    private static void Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string engine = Path.Combine(root, "tools", "godot", "Godot_v4.5.1-stable_win64.exe");
        if (!File.Exists(engine) || !File.Exists(Path.Combine(root, "project.godot")))
        {
            MessageBox.Show("Mantieni Spike Forever.exe nella cartella del gioco, insieme a tools, assets e src.", "Spike Forever");
            return;
        }
        string roaming = Path.Combine(root, ".runtime", "roaming");
        string local = Path.Combine(root, ".runtime", "local");
        Directory.CreateDirectory(roaming);
        Directory.CreateDirectory(local);
        var info = new ProcessStartInfo(engine, "--path \"" + root.TrimEnd(Path.DirectorySeparatorChar) + "\"");
        info.WorkingDirectory = root;
        info.UseShellExecute = false;
        info.CreateNoWindow = true;
        info.EnvironmentVariables["APPDATA"] = roaming;
        info.EnvironmentVariables["LOCALAPPDATA"] = local;
        try { Process.Start(info); }
        catch (Exception error) { MessageBox.Show(error.Message, "Spike Forever"); }
    }
}
