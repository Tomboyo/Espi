# Espi

Espi is a proof-of-concept declarative application framework that uses configuration and attributes to lift normal, unadultered functions into cron jobs, RabbitMQ messasge handlers, or other processes.

## An Example: Timeouts 

(To run this example, see examples/timeout.)

Suppose we have two functions that we want to invoke on a schedule. To configure them to run every _n_ milliseconds, we use the `Espi.Timeout` component like so:

```elixir
defmodule Example.Timeouts do
  use Espi
  alias Espi.Timeout
  require Logger

  @component {Timeout, schedule: 1_000}
  def fn1(), do: Logger.info("Function 1 called!")

  @component {Timeout, schedule: 1_500}
  def fn2(), do: Logger.info("Function 2 called")
end
```

This does not alter the functions in any way. When we `use Espi`, all the macro does is keep track of which functions have been registered as callbacks. When the Espi application starts, Espi will use that information to start our component processes. Espi starts automatically so long as :espi is a dependency of our application. We configure it like so:

```elixir
# config.exs
import Config

# Search for components in Example.* modules defined by our own application
config :espi,
  application: :example,
  namespace: Example
```

We configured Espi to search only modules loaded by our `:example` application and only under the `Example` namespace; we can see how in general, we could add or filter out components from our and other libraries. 

When our aplication starts, we will see our logging statements, as desired. Espi starts GenServers which use our functions as callbacks.

## Plugin Architecture

Espi is organized by feature into "plugin" packages. If an application only wants to declare Espi.Timeout components, it need only depend on the `:espi_timeout` package. For every feature, one package provides the capability. This lets us be choosy about the (transitive) dependencies we bring into the scope of our project, but also lets us define higher-order pckages to depend on named groups of useful Espi features. For example, we could create an `:espi_tutorial` package that depends on several intersting Espi features, possibly providing default configuration, to help a new user onboard themselves to the Espi framework.
