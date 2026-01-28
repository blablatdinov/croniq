# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

FROM hexpm/elixir:1.19.5-erlang-28.3-alpine-3.23.2 AS builder

ENV MIX_ENV=prod

RUN apk add --no-cache build-base git npm

RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

COPY mix.exs mix.lock ./

RUN mix deps.get --only prod && \
    mix deps.compile

COPY config/config.exs config/prod.exs config/runtime.exs config/

COPY assets assets
COPY priv priv
COPY lib lib

RUN mix assets.deploy && \
    mix compile && \
    mix release

FROM alpine:3.23.3 AS app

RUN apk add --no-cache openssl ncurses libstdc++

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/croniq ./
COPY --from=builder /app/config/prod.exs /app/config/runtime.exs ./config/

ENV MIX_ENV=prod
ENV PORT=4000

EXPOSE ${PORT}

CMD ["bin/croniq", "start"]
