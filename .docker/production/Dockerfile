########################
### app/rails config ###
########################

FROM public.ecr.aws/ideacrew/fdsh_gateway:base AS app

LABEL author="IdeaCrew"

# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH $BUNDLE_BIN:$GEM_HOME/gems/bin:$PATH

ARG BUNDLER_VERSION_OVERRIDE
ENV BUNDLER_VERSION=$BUNDLER_VERSION_OVERRIDE
RUN gem update --system && gem install bundler:$BUNDLER_VERSION

# Configure app home directory
ENV HOME /fdsh_gateway
RUN mkdir -p $HOME
WORKDIR $HOME
COPY . $HOME

RUN yarn install

# Setting env up
#ARG MEDICAID_GATEWAY_DB_HOST
#ARG MEDICAID_GATEWAY_DB_PORT
#ARG MEDICAID_GATEWAY_DB_NAME
#ARG RABBITMQ_URL
ENV RAILS_ENV='production'
ENV NODE_ENV='production'
#ENV MEDICAID_GATEWAY_DB_HOST=$MEDICAID_GATEWAY_DB_HOST
#ENV MEDICAID_GATEWAY_DB_PORT=$MEDICAID_GATEWAY_DB_PORT
#ENV MEDICAID_GATEWAY_DB_NAME=$MEDICAID_GATEWAY_DB_NAME
#ENV RABBITMQ_URL=$RABBITMQ_URL

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install --jobs 20 --retry 5 --without development test 
#RUN rm -f /fdsh_gateway/config/master.key && rm -f /fdsh_gateway/config/credentials.yml.enc

#CMD ["./entrypoints/docker-entrypoint.sh"]


########################
### web/nginx config ###
######################## 

FROM nginx:1.17.6-alpine as web

RUN mkdir /fdsh_gateway

# copy assets from the app build and nginx config
COPY --from=app /fdsh_gateway/public /fdsh_gateway/
COPY .docker/production/nginx.conf /etc/nginx/conf.d/fdsh_gateway.conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf-bkp

