FROM elixir:1.17.2-alpine AS build

# install build dependencies
RUN apk add --no-cache --update build-base git nodejs npm

# prepare build dir
WORKDIR /app
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# copy resources
COPY mix.exs mix.lock ./
COPY config config
COPY apps apps

RUN cd apps/web && mix setup
RUN mix deps.get && \
    mix deps.compile

RUN cd apps/web && mix assets.deploy
RUN mix phx.digest && \
    mix compile && \
    mix release document_pipeline_full


# runtime image
FROM alpine:3.20 AS app
RUN apk upgrade --no-cache && \
    apk add --no-cache openssl ncurses-libs libgcc libstdc++ && \
    apk add --no-cache inotify-tools bash

WORKDIR /app

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/document_pipeline_full ./

ENV PHX_SERVER=true

# Set default values for environment variables
ENV PIPELINE_PATH=/app/pipelines
ENV INPUT_PATH=/app/input
ENV OUTPUT_PATH=/app/output
ENV TMP_PATH=/app/tmp

# Don't change to nobody user here, as we need root to install packages
# RUN chown nobody:nobody /app
# USER nobody:nobody

ENTRYPOINT ["bin/document_pipeline_full"]
CMD ["start"]
