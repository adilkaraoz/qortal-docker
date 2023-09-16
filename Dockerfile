FROM eclipse-temurin:17.0.3_7-jre

RUN apt update
RUN apt -y upgrade
RUN apt install -y unzip
RUN apt install -y wget
RUN apt install -y p7zip-full
RUN wget https://github.com/Qortal/qortal/releases/latest/download/qortal.zip && unzip qortal.zip && cd qortal && chmod +x *.sh
RUN cd qortal && wget http://bootstrap.qortal.org/bootstrap-archive.7z
RUN cd qortal && 7za x bootstrap-archive.7z
RUN cd qortal && mkdir db && mv bootstrap/* db/.
RUN rm qortal.zip && rm qortal/bootstrap-archive.7z
COPY startup.sh .
RUN chmod +x startup.sh
COPY settings.json qortal/
CMD ["/bin/bash","-c","./startup.sh"]