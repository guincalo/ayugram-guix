#!/bin/sh
# Install the Guix binary release on a GitHub Actions Ubuntu runner, with a
# root guix-daemon and build users.  Substitutes: bordeaux first, then ci.
set -eu
v=1.5.0
tarball=guix-binary-$v.x86_64-linux.tar.xz
G=/var/guix/profiles/per-user/root/current-guix
cd "${RUNNER_TEMP:-/tmp}"
wget -nv "https://ftpmirror.gnu.org/gnu/guix/$tarball" \
  || wget -nv "https://ftp.gnu.org/gnu/guix/$tarball"
sudo tar --extract --file "$tarball" -C / --no-overwrite-dir
rm -f "$tarball"
sudo groupadd --system guixbuild
for i in $(seq -w 1 10); do
  sudo useradd -g guixbuild -G guixbuild -d /var/empty -s "$(which nologin)" \
    -c "Guix build user $i" --system "guixbuilder$i"
done
sudo mkdir -p /root/.config/guix
sudo ln -sfn "$G" /root/.config/guix/current
cat > guix-daemon.service <<UNIT
[Unit]
Description=Build daemon for GNU Guix

[Service]
ExecStart=$G/bin/guix-daemon --build-users-group=guixbuild --discover=no --substitute-urls='https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
Environment='GUIX_LOCPATH=$G/lib/locale' LC_ALL=en_US.utf8
OOMPolicy=continue
Restart=always
TasksMax=8192

[Install]
WantedBy=multi-user.target
UNIT
sudo cp guix-daemon.service /etc/systemd/system/guix-daemon.service
sudo systemctl daemon-reload
sudo systemctl enable --now guix-daemon.service
for f in "$G"/share/guix/*.pub; do
  sudo "$G/bin/guix" archive --authorize < "$f"
done
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$G/bin" >> "$GITHUB_PATH"
  echo "LANG=en_US.utf8" >> "$GITHUB_ENV"
fi
"$G/bin/guix" --version | head -1
