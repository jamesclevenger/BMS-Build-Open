FROM openjdk:8-jdk-buster 
#as bmsbuilder

#########################
# if you copied your github ssh key to local directory and named it id_rsa
# build with: 
# docker build --output out .
# example: docker build --output out .
#####
# it should work to use Docker ssh passthrough but it wasn't being recognized for me so going with the ssh key copy for now
# docker build --ssh default=<path to your ssh key> --output out .
# example: docker build --ssh default=/home/jclevenger/.ssh/id_rsa --output out .
############

USER root
ENV PATH="$PATH:."

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ENV NODE_VERSION 14.17.0

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
    && . /root/.nvm/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NVM_DIR /root/.nvm
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

#------ Start Maven Setup --------------------------------------------------------#
ARG MAVEN_VERSION=3.9.3

# 2- Define a constant with the working directory
ARG USER_HOME_DIR="/root"

# 3- Define the SHA key to validate the maven download
ARG SHA=400fc5b6d000c158d5ee7937543faa06b6bda8408caa2444a9c947c21472fde0f0b64ac452b8cec8855d528c0335522ed5b6c8f77085811c7e29e1bedbb5daa2

# 4- Define the URL where maven can be downloaded from
ARG BASE_URL=https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries

# 5- Create the directories, download maven, validate the download, install it, remove downloaded file and set links
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && echo "Downlaoding maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  \
  && echo "Checking download hash" \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  \
  && echo "Unziping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# 6- Define environmental variables required by Maven, like Maven_Home directory and where the maven repo is located
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

#------------- End Maven Setup --------------------------------------------#

# Shouldn't have to do this, the docker run param -ssh isn't working to clone the private repo (InventoryManager)
# so instead, copy in your ssh key into the container (but don't check it in to github)
RUN mkdir -p /root/.ssh
ADD id_rsa /root/.ssh/.
RUN chmod 600 /root/.ssh/id_rsa

RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# pull the repos
RUN mkdir /bmssource \
  && cd /bmssource \ 
  && git clone https://github.com/IntegratedBreedingPlatform/bms-config-template.git BMSConfig \
  && git clone https://github.com/IntegratedBreedingPlatform/BMSAPI.git \
  && git clone https://github.com/IntegratedBreedingPlatform/Middleware.git \ 
  && git clone https://github.com/IntegratedBreedingPlatform/Commons.git \
  && git clone https://github.com/IntegratedBreedingPlatform/Fieldbook.git \
  && git clone https://github.com/IntegratedBreedingPlatform/Workbench.git  \
  && git clone git@github.com:IntegratedBreedingPlatform/InventoryManager.git

WORKDIR /bmssource/Middleware
RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template 

WORKDIR /bmssource/Commons
RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template 

WORKDIR /bmssource/BMSAPI
RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template 

#WORKDIR /bmssource/BMSConfig
#RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template 

WORKDIR /bmssource/InventoryManager
RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template -e

WORKDIR /bmssource/Fieldbook
RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template -e

# would like to remove this, the git: prefixed repos in yarn.lock should be switched to https:
RUN sed -i 's/git:/https:/g' /bmssource/Workbench/src/main/web/yarn.lock

# there is an error that happens consistently when running yarn:
# ENOENT: no such file or directory
# This is a workaround
RUN sed -i 's/<arguments>install</<arguments>install --network-concurrency 1</' /bmssource/Workbench/pom.xml

WORKDIR /bmssource/Workbench
#RUN --mount=type=ssh mvn clean install -DskipTests -Duser.name=template -e

#FROM scratch AS export-stage
#COPY --from=bmsbuilder /bmssource/BMSAPI/target/bmsapi.war .
#COPY --from=bmsbuilder /bmssource/Fieldbook/target/Fieldbook.war .
#COPY --from=bmsbuilder /bmssource/InventoryManager/target/inventory-manager.war .
#COPY --from=bmsbuilder /bmssource/Workbench/target/Workbench.war .