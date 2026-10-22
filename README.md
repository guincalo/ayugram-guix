# ayugram-guix

[AyuGram Desktop](https://github.com/AyuGram/AyuGramDesktop) packaged for GNU Guix,
built in GitHub Actions. x86_64-linux only.

The repository is a Guix channel. The package `ayugram-desktop` is based on
Guix's `telegram-desktop` and builds AyuGram's release tag from a recursive git
checkout. A daily workflow picks up new AyuGram releases, updates the version
and source hash, and starts a build. Each build publishes a release with the
signed closure as a nar.

Builds are pinned to the Guix commit in `channels-lock.scm`.

## Install from a release (no local compile)

Authorize the signing key once:

    sudo guix archive --authorize < signing-key.pub

Download the `.nar.xz` from the latest release (and join the parts with `cat`
if it was split), then import it and install the store path given in the
release notes:

    xz -d < ayugram-desktop-VERSION-x86_64-linux.nar.xz | sudo guix archive --import
    guix package -i /gnu/store/...-ayugram-desktop-VERSION

The import brings the whole closure, so it works on any Guix revision. The
installed package does not follow `guix pull`; repeat the steps for new versions.

## Install from the channel (compiles locally)

Add this to `~/.config/guix/channels.scm`:

    (cons (channel
           (name 'ayugram)
           (url "https://github.com/guincalo/ayugram-guix")
           (branch "main"))
          %default-channels)

Then:

    guix pull
    guix install ayugram-desktop

This compiles AyuGram on your machine (an hour or more and several GB of disk),
because there is no substitute server for it. Guix skips the compile only if
the derivation is already in your store, for example after importing the
release nar while on the Guix commit from `channels-lock.scm`:

    guix time-machine -C channels-lock.scm -- install -L modules ayugram-desktop

## Build it yourself

    guix time-machine -C channels-lock.scm -- build -L modules ayugram-desktop

## Notes

- API credentials are the same ones Guix's `telegram-desktop` uses.
- The binary is called `AyuGram`.
- Not affiliated with AyuGram or Telegram.
