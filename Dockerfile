# Get the Ubuntu 16.04 Image

FROM ubuntu:16.04

# Set main labels

LABEL VERSION 1.0.0
LABEL Mainteiner JPB
LABEL Author-Email joaoback47@gmail.com

# Set Env Values

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NODE_VERSION=6.14.0 \
    IONIC_VERSION=1 \
    CORDOVA_VERSION=6

# Install all apts

RUN apt-get update &&  \
    dpkg --add-architecture i386 && \
    apt-get install -y -q git wget curl unzip python-software-properties software-properties-common \
    expect ant wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod zipalign && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Installing NodeJS and NPM

RUN curl --retry 3 -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
    tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.gz"

# Installing Cordova and Ionic

RUN npm install -g cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" gulp bower && \
    npm cache clear

# Adding Java PPA and installing Java 8.

RUN add-apt-repository ppa:webupd8team/java -y && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get update && apt-get -y install oracle-java8-installer && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adding Android Home as a Env Variable

RUN echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment

# Downloading and Installing Android SDK

RUN cd /opt && \
    mkdir android-sdk-linux && \
    cd android-sdk-linux && \ 
    curl --retry 3 -SLO https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip && \
    unzip sdk-tools-linux-3859397.zip && \
    rm -f sdk-tools-linux-3859397.zip && \
    chown -R root:root /opt && \
    cd tools && \
    mkdir templates 

# Setting Setup PATH

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:/opt/tools

# Android SDK installation

COPY tools /opt/tools
RUN ["/opt/tools/android-accept-licenses.sh", "android --use-sdk-wrapper update sdk --all --no-ui --filter tools,platform-tools,build-tools-25.0.0,android-25"]

# Adding missing gradle template

RUN curl --retry 3 -SLO https://dl.google.com/android/repository/tools_r25.2.5-linux.zip && \
    unzip tools_r25.2.5-linux.zip 'tools/templates/*' -d /opt/android-sdk-linux/ && \
    rm -f tools_r25.2.5-linux.zip

# Downloading gradle

RUN curl --retry 3 -SLO https://services.gradle.org/distributions/gradle-4.4.1-bin.zip && \ 
    mkdir /opt/gradle && \
    unzip -d /opt/gradle gradle-4.4.1-bin.zip && \
    ln -sf /opt/gradle/gradle-4.4.1/bin/gradle /usr/bin/gradle

# Creating a Launch Script

RUN cp /opt/tools/ionicx /usr/local/bin/ionicx && \
    cp /opt/tools/cordovax /usr/local/bin/cordovax


# Setting volumes and finishing up

VOLUME [ "/data","/root/.gradle", "/root/.android"]
WORKDIR /data
EXPOSE 8100 35729
ENTRYPOINT ["ionicx"]
CMD ["serve"]