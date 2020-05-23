FROM ubuntu as build

ARG EMBY_VERSION=4.5.0.11

RUN mkdir -p /work/ffmpeg && cd /work && apt-get update && apt-get -qy install curl tar xz-utils && \
    curl -sLO https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz && ls && \
    tar -xvf ffmpeg-release-amd64-static.tar.xz -C ffmpeg --strip-components 1
RUN mkdir -p /work/emby && cd /work/emby && apt-get install unzip && \
    curl -sLO https://github.com/MediaBrowser/Emby.Releases/releases/download/${EMBY_VERSION}/embyserver-netcore_${EMBY_VERSION}.zip && \
    unzip embyserver-netcore_${EMBY_VERSION}.zip && ls

FROM mcr.microsoft.com/dotnet/core/runtime:3.1
COPY --from=build /work/ffmpeg /usr/share/bin/ffmpeg
COPY --from=build /work/emby /usr/share/emby
RUN apt-get update && apt-get install -qqy gpg && \
    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu focal main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F && \
    apt-get update && apt-get dist-upgrade -qy && apt-get install -qqy libsqlite3-dev && chmod +x /usr/share/emby/system/EmbyServer
ENTRYPOINT ["/usr/share/emby/system/EmbyServer"]
CMD ["-programdata", "/config", "-ffdetect", "/usr/share/bin/ffmpeg/ffdetect", "-ffmpeg", "/usr/share/bin/ffmpeg/ffmpeg", "-ffprobe", "/usr/share/bin/ffmpeg/ffprobe"]
