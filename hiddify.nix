{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "hiddify-next";
  version = "4.1.1";
  src = fetchurl {
    url = "https://github.com/hiddify/hiddify-app/releases/download/v${version}/Hiddify-Linux-x64-AppImage.AppImage";
    hash = "sha256-6yu2wIlxuY4tCgH8W2R+KboXsWYRScyfl+2g53v1vcM=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs =
    pkgs: with pkgs; [
      libepoxy
      zstd
    ];
  extraInstallCommands = ''
    mv $out/bin/${pname}* $out/bin/hiddify
    install -Dm644 ${appimageContents}/hiddify.desktop $out/share/applications/hiddify.desktop
    cp -a ${appimageContents}/usr/share/icons $out/share/
    substituteInPlace $out/share/applications/hiddify.desktop \
      --replace 'LD_LIBRARY_PATH=usr/lib ' ''''''
  '';

  meta = {
    description = "Multi-platform auto-proxy client (appimage version)";
    longDescription = ''
      Multi-platform auto-proxy client, supporting Sing-box, X-ray, TUIC, Hysteria, Reality, Trojan, SSH etc.
    '';
    homepage = "https://github.com/hiddify/hiddify-next";
    license = lib.licenses.cc-by-nc-sa-40;
    platforms = [ "x86_64-linux" ];
    mainProgram = "hiddify";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
