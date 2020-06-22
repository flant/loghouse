FROM nginx:stable-alpine

ENV APP_HOME /usr/share/nginx/html
ENV TMP_DIR /tmp/tabix
ENV DEFAULT /etc/nginx/sites-enabled/default
ENV TABIX_RELEASE 18.07.1

WORKDIR $APP_HOME
RUN mkdir ${TMP_DIR} && wget https://github.com/tabixio/tabix/archive/${TABIX_RELEASE}.tar.gz -O ${TMP_DIR}/tabix.tar.gz \
    && cd ${TMP_DIR} && tar -xvf tabix.tar.gz && rm -rf ${APP_HOME}/* \
    && mv ${TMP_DIR}/tabix-${TABIX_RELEASE}/build/* ${APP_HOME} && rm -rf ${TMP_DIR}
