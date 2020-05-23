FROM ubuntu as build

ARG EMBY_VERSION=4.5.0.11
ARG EMBY_FFMPEG_VERSION=2020_02_24

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN mkdir -p /work/ffmpeg && cd /work && apt-get update && apt-get -qy install yasm pkg-config build-essential curl tar xz-utils gzip && \
    curl -sLO https://mediabrowser.github.io/embytools/ffmpeg-${EMBY_FFMPEG_VERSION}.tar.gz && ls && \
    tar -xzvf ffmpeg-${EMBY_FFMPEG_VERSION}.tar.gz && cd ffmpeg-${EMBY_FFMPEG_VERSION}_public && ./configure && make -j 14 && \
    mv -v ffmpeg /work/ffmpeg/ && mv -v ffprobe /work/ffmpeg/
RUN mkdir -p /work/ffdetect && cd /work && curl -sLO https://mediabrowser.github.io/embytools/ffdetect-${EMBY_FFMPEG_VERSION}-x64.tar.xz && \
    tar -xvf ffdetect-${EMBY_FFMPEG_VERSION}-x64.tar.xz -C ffdetect --strip-components 1
RUN mkdir -p /work/emby && cd /work && apt-get install unzip && \
    curl -sLO https://github.com/MediaBrowser/Emby.Releases/releases/download/${EMBY_VERSION}/embyserver-netcore_${EMBY_VERSION}.zip && \
    unzip embyserver-netcore_${EMBY_VERSION}.zip -d /work/emby

FROM mcr.microsoft.com/dotnet/core/runtime:3.1
COPY --from=build /work/ffmpeg /usr/share/bin/ffmpeg
COPY --from=build /work/ffdetect /usr/share/bin/ffdetect
COPY --from=build /work/emby /usr/share/emby
RUN sed -i "s#deb http://deb.debian.org/debian buster main#deb http://deb.debian.org/debian buster main non-free contrib#g" /etc/apt/sources.list
RUN apt-get update && apt-get install -qqy gpg aptitude curl software-properties-common
RUN curl -sLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
RUN echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu focal main" > /etc/apt/sources.list.d/000-toolchain.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F && \
    echo "deb http://www.deb-multimedia.org buster main" > /etc/apt/sources.list.d/001-multimedia.list && apt-get update -oAcquire::AllowInsecureRepositories=true && apt-get install -qqy --allow-unauthenticated deb-multimedia-keyring && \
    echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update && apt-get dist-upgrade -qy && aptitude install -y vdpau-driver-all libmfx1 libva-dev libdrm-dev libva2 libva-drm2 libva-glx2 libsqlite3-dev libcuda1 libnvidia-encode1 && chmod +x /usr/share/emby/system/EmbyServer
ENTRYPOINT ["/usr/share/emby/system/EmbyServer"]
CMD ["-programdata", "/config", "-ffdetect", "/usr/share/bin/ffdetect/ffdetect", "-ffmpeg", "/usr/share/bin/ffmpeg/ffmpeg", "-ffprobe", "/usr/share/bin/ffmpeg/ffprobe"]
