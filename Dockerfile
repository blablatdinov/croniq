FROM elixir:1.18-alpine AS build

RUN apk add --no-cache build-base npm git postgresql-client

WORKDIR /app
COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    MIX_ENV=prod mix compile && \
    npm install --prefix assets && \
    MIX_ENV=prod mix assets.deploy && \
    MIX_ENV=prod mix release

FROM alpine:3.16

RUN apk add --no-cache openssl ncurses-libs libstdc++ postgresql-client

WORKDIR /app
COPY --from=build /app/_build/prod/rel/croniq ./

ENV PORT=4010
EXPOSE 4010

CMD ["/app/bin/croniq", "start"]
