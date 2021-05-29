defmodule My.Consumer do
  use Espi

  @component true
  def foo(x), do: IO.inspect(x)
end

defmodule Not.My.Consumer do
  use Espi

  @component true
  def bar(_), do: IO.puts("NO!")
end

defmodule My.App do
  use Application

  def start(_type, _args) do
    children = [
      {Espi, [app: :espi, root: My]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
