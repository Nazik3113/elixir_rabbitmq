FROM elixir:1.13.3-alpine as build

RUN mkdir /app
WORKDIR /app

RUN mix local.rebar --force && \
    mix local.hex --force

ENV MIX_ENV="prod"

COPY mix.exs .
COPY mix.lock .

RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

COPY lib ./lib
COPY config ./config

RUN mix compile
RUN mix release 

FROM alpine:3.15.0 AS app

RUN apk add --update bash
RUN apk add --no-cache libstdc++

RUN mkdir /app

WORKDIR /app

COPY --from=build /app/_build/prod/rel/elixir_rabbitmq .

RUN chown -R nobody: /app

USER nobody

ENV HOME=/app

CMD ["/app/bin/elixir_rabbitmq", "start"]