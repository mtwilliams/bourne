# Bourne

[![Continuous Integration](https://img.shields.io/travis/mtwilliams/bourne/master.svg)](https://travis-ci.org/mtwilliams/bourne)
[![Code Coverage](https://img.shields.io/coveralls/mtwilliams/bourne/master.svg)](https://coveralls.io/github/mtwilliams/bourne)
[![Documentation](http://inch-ci.org/github/mtwilliams/bourne.svg)](http://inch-ci.org/github/mtwilliams/bourne)
[![Package](https://img.shields.io/hexpm/dt/bourne.svg)](https://hex.pm/packages/bourne)

Bourne provides more powerful streaming mechanisms than those offered by [Ecto](https://github.com/elixir-ecto/ecto) or [Tributary](https://github.com/DavidAntaramian/tributary). Notably, it provides both cursor and keyset pagination methods, as well as the ability to create a `GenStage` producer with similar semantics to `GenStage.from_enumerable`.

## Example

```elixir
defmodule My.Repo
  use Ecto.Repo, otp_app: :mine
  use Bourne
end

import Ecto.Query
q = from(actor in Actor, where: actor.born <= 1980)

# You can stream through an `Enumerable`:
Bourne.stream(q) |> Stream.each(&IO.inspect) |> Stream.run

# Alternatively, you can stream through a GenStage producer:
defmodule InspectorConsumer do
  use GenStage

  def start_link do
    GenStage.start_link(InspectorConsumer, [])
  end

  def init([]) do
    {:consumer, :ok}
  end

  def handle_events(rows, _from, state) do
    Enum.each(rows, &IO.inspect/1)
    {:noreply, [], state}
  end
end

{:ok, producer} = Bourne.streamer(q, method: :keyset)
{:ok, consumer} = InspectorConsumer.start_link
GenStage.sync_subscribe(consumer, to: producer)
```

## Installation

  1. Add `bourne` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:bourne, "~> 0.0.0"}]
  end
  ```

  2. Fetch and compile your new dependency:

  ```
  mix do deps.get bourne, deps.compile
  ```

  3. Drink your :tea:

  4. That's it!

## Usage

Refer to the [documentation](https://hexdocs.pm/bourne/Bourne.html).

## License

Bourne is free and unencumbered software released into the public domain, with fallback provisions for jurisdictions that don't recognize the public domain.

For details, see `LICENSE.md`.
