FROM centos:6.6
MAINTAINER Takeshi Miyajima <rozyhead@gmail.com>

# TimeZoneの設定
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock

# yumアップデート
RUN yum -y update

# yum installのエラー回避
# https://github.com/CentOS/sig-cloud-instance-images/issues/15#issuecomment-252563831
RUN yum install -y yum-plugin-ovl

# apacheのインストール
RUN yum install -y httpd

# apacheの設定
RUN rm -rf /etc/httpd/conf.d/welcom.conf
RUN sed -ri '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/    AllowOverride None/    AllowOverride All/' /etc/httpd/conf/httpd.conf && \
    sed -ri '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/    Options Indexes FollowSymLinks/    Options Indexes FollowSymLinks Includes/' /etc/httpd/conf/httpd.conf && \
    sed -ri 's/DirectoryIndex index.html index.html.var/DirectoryIndex index.html index.shtml index.html.var/' /etc/httpd/conf/httpd.conf

# remiリポジトリの登録
RUN rpm -Uvh http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# wgetのインストール
RUN yum install -y wget

# libcurlをインストール(php5.1に必要)
RUN yum install -y libcrypto.so.6 libssl.so.6 openssl098e-0.9.8e && \
    wget ftp://rpmfind.net/linux/remi/enterprise/5/remi/x86_64/compat-libcurl3-7.15.5-3.el5.remi.x86_64.rpm && \
    rpm -Uvh compat-libcurl3-7.15.5-3.el5.remi.x86_64.rpm

# mysql5.0のインストール(php5.1のインストールに必要)
RUN yum install -y libpcap && \
    wget https://dl.iuscommunity.org/pub/ius/archive/CentOS/5/x86_64/mysqlclient15-5.0.92-3.ius.centos5.x86_64.rpm && \
    rpm -Uvh mysqlclient15-5.0.92-3.ius.centos5.x86_64.rpm

# php5.1関連ファイルをダウンロード
RUN wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-cli-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-common-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-gd-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-mbstring-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-xml-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-pdo-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-devel-5.1.6-45.el5_11.x86_64.rpm && \
    wget http://vault.centos.org/5.11/updates/x86_64/RPMS/php-mysql-5.1.6-45.el5_11.x86_64.rpm

# php5.1のインストール
RUN yum localinstall -y \
        php-5.1.6-45.el5_11.x86_64.rpm \
        php-devel-5.1.6-45.el5_11.x86_64.rpm \
        php-cli-5.1.6-45.el5_11.x86_64.rpm \
        php-common-5.1.6-45.el5_11.x86_64.rpm \
        php-pdo-5.1.6-45.el5_11.x86_64.rpm \
        && \
    yum localinstall -y \
        php-xml-5.1.6-45.el5_11.x86_64.rpm \
        php-gd-5.1.6-45.el5_11.x86_64.rpm \
        php-mbstring-5.1.6-45.el5_11.x86_64.rpm \
        php-mysql-5.1.6-45.el5_11.x86_64.rpm

# phpの設定
RUN sed -ri 's/;date.timezone =/date.timezone = Asia\/Tokyo/' /etc/php.ini && \
    sed -ri 's/display_errors = Off/display_errors = On/' /etc/php.ini && \
    sed -ri 's/post_max_size = 8M/post_max_size = 100M/' /etc/php.ini && \
    sed -ri 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php.ini && \
    sed -ri 's/;mbstring.language = Japanese/mbstring.language = Japanese/' /etc/php.ini && \
    sed -ri 's/;mbstring.internal_encoding = EUC-JP/mbstring.internal_encoding = UTF-8/' /etc/php.ini && \
    sed -ri 's/;mbstring.http_input = auto/mbstring.http_input = pass/' /etc/php.ini && \
    sed -ri 's/;mbstring.http_output = SJIS/mbstring.http_output = pass/' /etc/php.ini && \
    sed -ri 's/;mbstring.encoding_translation = Off/mbstring.encoding_translation = Off/' /etc/php.ini

# ruby2.5.1のインストール
RUN yum install -y git which tar bzip2 gcc openssl-devel readline-devel zlib-devel
RUN git clone https://github.com/rbenv/rbenv.git /opt/rbenv
RUN mkdir /opt/rbenv/plugins && \
    git clone https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build && \
    /opt/rbenv/plugins/ruby-build/install.sh
ENV PATH /opt/rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /root/.bashrc
ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install 2.5.1 && rbenv global 2.5.1

# mailcatcherのインストール
RUN yum install -y gcc-c++ sqlite-devel
RUN bash -l -c 'gem install mailcatcher'
# apacheユーザーがcachemailコマンドを実行できるようにする
RUN chmod +x /root
RUN sed -ri 's/sendmail_path = \/usr\/sbin\/sendmail -t -i/sendmail_path = \/root\/.rbenv\/shims\/catchmail/' /etc/php.ini

# supervisordのインストール
RUN yum install -y supervisor

# supervisordの設定
RUN touch /etc/supervisord.conf
RUN echo '[supervisord]' >> /etc/supervisord.conf
RUN echo 'nodaemon=true' >> /etc/supervisord.conf
RUN echo '[program:apache]' >> /etc/supervisord.conf
RUN echo 'command=/usr/sbin/apachectl -DFOREGROUND' >> /etc/supervisord.conf
RUN echo '[program:mailcatcher]' >> /etc/supervisord.conf
RUN echo 'command=/bin/bash -l -c "mailcatcher -f --ip=0.0.0.0"' >> /etc/supervisord.conf

EXPOSE 80 1025 1080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

