FROM silex/emacs:28.1

COPY ./init.el /root/.emacs.d/init.el
WORKDIR /data

ENV DEBIAN_FRONTEND=noninteractive

# Locale work is a combo of "https://stackoverflow.com/a/9727654/4359699",
# "https://stackoverflow.com/a/38553499/4359699", and my own trial and error.

# I can't tell if this is genius or horrific.
RUN apt-get update && \
    # Also upgrade all packages, just in case of security updates.
    apt-get upgrade -y && \
    # First update the locale, so we can install the other packages with the
    # UTF-8 locale set.
    apt-get install -y --no-install-recommends locales && \
    # Use dpkg-reconfigure to do all the locale magic for us. Values generated
    # by running dpkg-reconfigure interactively, then looking at
    # debconf-get-selections.
    printf '%s\n%s\n' \
        'locales	locales/locales_to_be_generated	multiselect	en_US.UTF-8 UTF-8' \
        'locales	locales/default_environment_locale	select	en_US.UTF-8' \
    | debconf-set-selections && \
    # A bug in dpkg-reconfigure, I think. In noninteractive mode it doesn't
    # properly regenerate this file based on the selections set by
    # debconf-set-selections.
    rm /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    # Only now set these envvars
    export LANG=en_US.UTF-8 && \
    export LC_ALL=en_US.UTF-8 && \
    apt-get install -y --no-install-recommends latexml && \
    emacs --script /root/.emacs.d/init.el \
          --eval "(progn \
  (package-refresh-contents) \
  (package-install 'dash) \
  (package-install 'htmlize) \
  (package-install 's) \
  )" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Necessary for non-ASCII codepoints in filenames. Don't set these too early,
# because the locale files must be installed and configured and available, or
# else apt-get itself will get confused while installing them (because it
# expects them to be available, already).
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

CMD ["emacs", "--batch", "--load", "/root/.emacs.d/init.el", "--load", "publish.el"]
