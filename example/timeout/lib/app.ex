# Declare two timeout components, which will run on a fixed schedule when we launch our application.
defmodule Example.Timeouts do
  use Espi

  alias Espi.Timeout

  require Logger

  @component {Timeout, schedule: 1_000}
  def fn1(), do: Logger.info("Function 1 called!")

  def boom(), do: raise("I am not a component.")

  @component {Timeout, schedule: 1_500}
  def fn2(), do: Logger.info("Function 2 called")
end

# Espi can search nested namespaces for components.
defmodule Example.More.Timeouts do
  use Espi

  alias Espi.Timeout

  require Logger

  @component {Timeout, schedule: 2_000}
  def fn3(), do: Logger.info("Function 3 called")
end

# This module is not under the configured namespace, so its components are not started with our application.
defmodule Foo.Bar.Components do
  use Espi

  alias Espi.Timeout

  @component {Timeout, schedule: 500}
  def bar(), do: raise("I am ignored because of my namespace")
end
