FROM registry.access.redhat.com/rhel7
MAINTAINER Snapt Inc <support@snapt.net>
ENV container docker
### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="SnaptADC" \
      maintainer="support@snapt.net" \
      vendor="Snapt" \
      version="1.0" \
      release="1" \
      summary="Snapt Application Delivery Controller (ADC)" \
      description="The Snapt ADC ensures your website or service is always online, performing quickly and safe from threats.Snapt provides high-end virtualized and cloud-based load balancing, web acceleration and security software for your critical services." \
### Required labels above - recommended below
      url="https://www.snapt.net" \
      run='docker run -di -p 8080:8080 snaptadc/snapt:latest' \
      io.k8s.description="The Snapt ADC ensures your website or service is always online, performing quickly and safe from threats.Snapt provides high-end virtualized and cloud-based load balancing, web acceleration and security software for your critical services." \
      io.k8s.display-name="Snapt ADC" \
      io.openshift.expose-services="8080/tcp:httpUIaccess,29987/tcp:syslog" \
      io.openshift.tags="snapt,adc"

### Atomic Help File - Write in Markdown, it will be converted to man format at build time.
### https://github.com/projectatomic/container-best-practices/blob/master/creating/help.adoc
COPY help.md /tmp/

### add licenses to this directory
RUN mkdir /licenses
COPY licenses /licenses

### Add necessary Red Hat repos here
RUN rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms,nginx/x86_64 \
### Add your package needs here
    INSTALL_PKGS="golang-github-cpuguy83-go-md2man wget net-tools lshw dmidecode psmisc openssl \
    haproxy keepalived vim cronie ca-certificates sudo squid nginx gcc-c++ pcre-devel zlib-devel \
    make unzip geoip-devel iproute hostname systemd initscripts" && \
    yum -y update-minimal --disablerepo "*" --enablerepo rhel-7-server-rpms --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
### help file markdown to man conversion
    go-md2man -in /tmp/help.md -out /help.1 && \
    yum clean all

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done)
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
rm -f /etc/systemd/system/*.wants/* \
rm -f /lib/systemd/system/local-fs.target.wants/* \
rm -f /lib/systemd/system/sockets.target.wants/*udev* \
rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
rm -f /lib/systemd/system/basic.target.wants/* \
rm -f /lib/systemd/system/anaconda.target.wants/*

# Download SNAPT
RUN wget https://downloads.snapt.net/fetch/redhat \
	&& tar -C / -xvf ./redhat \
	&& rm -f redhat

COPY snapt_nginx_builder.sh /tmp/
RUN chmod 777 /tmp/snapt_nginx_builder.sh
RUN ./tmp/snapt_nginx_builder.sh
RUN rm /tmp/snapt_nginx_builder.sh \
	&& rm -rf /var/tmp/yum*

COPY nginx.service /lib/systemd/system/nginx.service
RUN mkdir -p /var/lib/nginx/body
COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod 777 /etc/nginx/nginx.conf

RUN echo "/usr/local/snapt/start.sh" >> /etc/rc.local
RUN chmod u+x /etc/rc.d/rc.local

RUN systemctl enable crond
RUN systemctl enable haproxy
RUN systemctl enable nginx
#RUN systemctl enable keepalived
RUN systemctl enable squid

#Create persistent volumes
VOLUME ["/usr/local/snapt", "/etc/haproxy", "/etc/nginx", "/var", "/sys/fs/cgroup"]

EXPOSE 8080
EXPOSE 29987

CMD ["/usr/sbin/init"]


