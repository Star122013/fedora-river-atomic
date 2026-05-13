# vim: set filetype=dockerfile
# ================================================================
# Fedora 44 with bootc 
# https://bootc.dev/bootc/
# Philosophy: the image provides hardware support + a working
# niri session.
#
# File placement rules (bootc):
#   /usr/lib/   — read-only distro defaults (modprobe.d, dracut, systemd, sddm)
#   /etc/       — mutable admin config (containers policy, skel, locale)
#   /var/       — runtime state only; never ship files here; use tmpfiles.d
# ================================================================


# stage 1 use fedora build some software
# niri-builder
# use niri copr instead
# maple fonts
FROM alpine AS fonts-downloader

RUN apk add --no-cache curl jq unzip

WORKDIR /fonts

RUN set -e; \
  download_and_unzip() { \
  local repo=$1 file=$2 dest=$3; \
  local tag=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r ".tag_name"); \
  echo "Downloading ${repo} ${tag}..."; \
  curl -L "https://github.com/${repo}/releases/download/${tag}/${file}" -o "/tmp/${file}"; \
  mkdir -p "${dest}"; \
  unzip -q "/tmp/${file}" -d "${dest}"; \
  rm "/tmp/${file}"; \
  }; \
  download_and_unzip "subframe7536/maple-font" "MapleMono-NF-CN.zip" "maple-mono-nf-cn" && \
  download_and_unzip "ryanoasis/nerd-fonts" "NerdFontsSymbolsOnly.zip" "nerd-fonts-symbols-only"

# FROM fedora AS waybar-builder
# RUN dnf builddep -y waybar && \
#   dnf copr enable -y celestelove/libcava && \
#   dnf install -y git iniparser-devel fftw-devel alsa-lib-devel pulseaudio-libs-devel libcava-devel
# WORKDIR /tmp
# RUN git clone https://github.com/Alexays/Waybar.git --depth=1 -b master /tmp/waybar
# WORKDIR /tmp/waybar
# RUN meson setup \
#   --prefix=/usr \
#   --buildtype=plain \
#   --auto-features=disabled \
#   --wrap-mode=nodownload \
#   -Dexperimental=true \
#   -Ddbusmenu-gtk=enabled \
#   -Dlibinput=enabled \
#   -Dlibnl=enabled \
#   -Dupower_glib=enabled \
#   -Dmpris=enabled \
#   -Dpulseaudio=enabled \
#   -Dlibevdev=enabled \
#   -Dlibudev=enabled \
#   -Dmpd=enabled \
#   -Djack=enabled \
#   -Drfkill=enabled \
#   -Dsndio=disabled \
#   -Dsystemd=enabled \
#   -Dlogind=enabled \
#   -Dman-pages=enabled \
#   -Dwireplumber=enabled \
#   -Dpipewire=enabled \
#   -Dcava=enabled \
#   -Dtests=disabled \
#   build && \
#   ninja -C build && \
#   mkdir -pv /output/waybar/usr/bin && \
#   install -Dm 755 /tmp/waybar/build/waybar /output/waybar/usr/bin/waybar

# stage 2 make system container
FROM quay.io/fedora/fedora-kinoite:44

COPY rootfs/ /
COPY build /tmp/build

# bootstrap nushell, then let Nu orchestrate repos/packages/services
RUN dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
  && dnf copr enable -y atim/nushell \
  && dnf install -y nushell \
  && dnf clean all

# 3.desktop
# COPY --from=niri-builder /out/runtime /
# COPY --from=waybar-builder /output/waybar /
COPY --from=fonts-downloader /fonts /usr/share/fonts/
RUN nu /tmp/build/scripts/build.nu /tmp/build

# # 4.audio
# RUN dnf install -y --setopt=install_weak_deps=False --nodocs \
#   pipewire \
#   pipewire-pulseaudio \
#   pipewire-alsa \
#   wireplumber \
#   rtkit \
#   && dnf clean all

# # 5.system service
# RUN dnf install -y --setopt=install_weak_deps=False --nodocs \
#   NetworkManager \
#   bluez \
#   bluez-obexd \
#   polkit \
#   udisks2 \
#   gnome-keyring \
#   avahi \
#   nss-mdns \
#   firewalld \
#   fwupd \
#   && dnf clean all

# 8.grub
# RUN mkdir -p /usr/share/grub/themes
# COPY --from=grub-builder /usr/share/grub/themes/ /usr/share/grub/themes/
# RUN sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/elegant/theme.txt"|' /etc/default/grub \
#   && sed -i 's|^GRUB_GFXMODE=.*|GRUB_GFXMODE="1920x1080x32"|' /etc/default/grub \
#   && sed -i 's|^GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|' /etc/default/grub

# 9. flatpak
# handled by /tmp/build/scripts/build.nu

# 10.zram
# handled by /tmp/build/scripts/build.nu

# 11.selinux
# RUN restorecon -RFv \
#   /usr/lib/bootc \
#   /usr/lib/dracut \
#   /usr/lib/modprobe.d \
#   /usr/lib/sddm \
#   /usr/lib/sysusers.d \
#   /usr/lib/systemd \
#   /usr/lib/tmpfiles.d \
#   /usr/share/wayland-sessions \
#   /etc/containers \
#   /etc/environment \
#   /etc/locale.conf \
#   /etc/skel \
#   2>/dev/null || true \
#   && systemd-sysusers


# 12.systemctl
# handled by /tmp/build/scripts/build.nu
#   bluetooth.service
#   firewalld.service
#   avahi-daemon.service

# 13.bootc lint
# handled by /tmp/build/scripts/build.nu
