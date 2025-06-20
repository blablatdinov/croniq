FROM hexpm/elixir:1.18.4-erlang-28.0.1-alpine-3.21.3 AS builder

ENV MIX_ENV=prod

# Устанавливаем зависимости для сборки
RUN apk add --no-cache build-base git npm

# Устанавливаем hex и rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Создаем рабочую директорию
WORKDIR /app

# Копируем файлы зависимостей
COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/dev.exs config/

# Устанавливаем зависимости
RUN mix deps.get --only prod && \
    mix deps.compile

# Копируем остальные файлы приложения
COPY assets assets
COPY priv priv
COPY lib lib

# Собираем приложение
RUN mix assets.deploy && \
    mix compile && \
    mix release

# Шаг 2: Запуск приложения
FROM alpine:3.19.1 AS app

# Устанавливаем зависимости для запуска
RUN apk add --no-cache openssl ncurses libstdc++

WORKDIR /app

# Копируем собранный релиз из предыдущего этапа
COPY --from=builder /app/_build/prod/rel/croniq ./

# Указываем переменные среды по умолчанию
ENV MIX_ENV=prod
ENV PORT=4000

# Открываем порт
EXPOSE ${PORT}

# Команда запуска
CMD ["bin/croniq", "start"]
