FROM ubuntu:16.04

LABEL author="Russ Brown" \
      version="0.0.1" \
      description="Tooling for working with Jekyll" \
      source="https://github.com/rcbrown/jekyll"

# C layer - These are required for building native code in some of the gems Jekyll will pull in below

RUN apt-get update \
    && apt-get install -y build-essential=12.1ubuntu2 \
    && apt-get install -y zlib1g-dev=1:1.2.8.dfsg-2ubuntu4.1

# Javascript layer - Debian distro version of nodejs is quite old. Nodesource's fresher install requires running
# their script (https://deb.nodesource.com/setup_6.x) to install, but there was no way to pin versions using that,
# so I had to reverse-engineer it.
#
# Nodesource doesn't keep old versions, so if the pinned version below is not found, you can find the current versions
# at https://deb.nodesource.com/node_6.x/dists/xenial/main/binary-amd64/Packages.

COPY nodesource.gpg.key /

RUN apt-get update \
    && apt-get install -y apt-transport-https=1.2.24 \
    && apt-key add /nodesource.gpg.key \
    && echo 'deb https://deb.nodesource.com/node_6.x xenial main' > /etc/apt/sources.list.d/nodesource.list \
    && echo 'deb-src https://deb.nodesource.com/node_6.x xenial main' >> /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install nodejs=6.11.2-1nodesource1~xenial1 \
    && npm install -g local-web-server@2.2.4 \
    && rm /nodesource.gpg.key

# Ruby layer

ENV mntjekyll /mnt/jekyll

RUN apt-get install -y ruby-dev=1:2.3.0+1 \
    && gem install bundler -v 1.15.3 \
    && gem install jekyll -v 3.0.5 \
    && mkdir -p ${mntjekyll}

# The bundle installation is slow and is an extra step that the user of the image would need to perform. By preloading
# the Gemfile and lock from what we presume will be the same as what's in the site repo, we can save a lot of time.
# But if we change any versions the blog uses, we will need to update the Gemfile and Gemfile.lock in this image.

WORKDIR ${mntjekyll}
COPY Gemfile Gemfile.lock ./
RUN bundle install \
    && rm Gemfile Gemfile.lock

# Tools layer

RUN apt-get install -y vim=2:7.4.1689-3ubuntu1.2 \
    && echo 'set -o vi' > /root/.bashrc \
    && apt-get install -y curl=7.47.0-1ubuntu2.2

EXPOSE 4000
