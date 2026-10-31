FROM elixir:1.20-slim AS build
ENV MIX_ENV=prod
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile
COPY ilb ./lib
RUN mix release

FROM elixir:1.20-slim
WORKDIR /app
COPY --from=build /app/_build/prod/rel/shortener ./
ENV PORT=4000
EXPOSE 4000
CMD ["bin/shortener", "start"]