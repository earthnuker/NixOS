{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      ytdl-format = "bestvideo[vcodec!=av01]+bestaudio/best";
      video-sync = "display-resample";
      interpolation = "yes";
      hwdec = "vaapi";
      hwdec-codecs = "all";
      scale = "ewa_lanczossharp";
      vo = "gpu";
      gpu-context = "drm";
    };
    scripts = with pkgs.mpvScripts; [
      mpris
      modernz
    ];
  };
}
