defmodule Example.Components do
  use Espi

  alias Espi.Timeout

  require Logger

  @component {Espi.Timeout, schedule: 1_000}
  def fn1(_), do: Logger.info("Function 1 called!")

  @component {Timeout, schedule: 1_500}
  def fn2(_), do: Logger.info("Function 2 called")
end

defmodule Example.More.Components do
  use Espi

  alias Espi.Timeout

  require Logger

  @component {Timeout, schedule: 2_000}
  def fn3(_), do: Logger.info("Function 3 called")
end

defmodule Foo.Bar.Components do
  use Espi

  alias Espi.Timeout

  @component {Timeout, schedule: 500}
  def bar(_), do: raise "I am ignored because of my namespace"
end

defmodule Example.App do
  use Application

  def start(_type, _args) do
    children = [
      # Scan for components defined in our Example.* modules.
      {Espi, [app: :timeout, namespace: Example]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
