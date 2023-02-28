FROM elixir:1.14.2-alpine AS build

# prepare build dir
WORKDIR /app

RUN apk add git

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
ENV SECRET_KEY_BASE=yORg910Gzl54nSsy1HQ1OkKh0sDIj+0eKcSCdt/nyLSl25q41t4Uayqr8BZHSJrI
RUN mix do deps.get, deps.compile

# compile and build release
COPY lib lib
RUN mix do compile, release

# prepare release image
FROM alpine:3.16 AS app
RUN apk add --no-cache openssl libgcc libstdc++ ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/server ./

ENV HOME=/app

CMD ["bin/server", "start"]
