FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y openjdk-11-jdk curl wget git docker.io gnupg2 lsb-release unzip && \
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | gpg --dearmor -o /usr/share/keyrings/jenkins.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list && \
    apt-get update && apt-get install -y jenkins

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/bin/install-jenkins.sh

EXPOSE 8080
CMD ["java", "-jar", "/usr/share/jenkins/jenkins.war"]
