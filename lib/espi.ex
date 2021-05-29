defmodule Espi do
  require Logger

  # https://elixirforum.com/t/nicest-way-to-emulate-function-decorators/2050/26
  defmacro __using__(_) do
    quote do
      @on_definition Espi
      @before_compile Espi
      @components []

      @component nil
    end
  end

  def __on_definition__(env, kind, fun, args, _guards, _body) do
    if Module.get_attribute(env.module, :component) do
      if kind != :def do
        raise "Only public functions may be @components"
      end

      components = Module.get_attribute(env.module, :components)
      components = [{env.module, fun, length(args)} | components]
      Module.put_attribute(env.module, :components, components)
      Module.put_attribute(env.module, :component, nil)
    end

    :ok
  end

  defmacro __before_compile__(_env) do
    quote do
      def components, do: @components
    end
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  def start_link(opts) do
    {:ok, app} = Keyword.fetch(opts, :app)
    root = Keyword.get(opts, :root, nil)

    children =
      for {m, f, _arity} <- scan(app, root) do
        {Espi.RabbitQueue.Server, [impl: {m, f}]}
      end

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def scan(app, root) do
    if :code.get_mode() == :interactive do
      Logger.warn("Scanning in :interactive mode (are you in iex?)")
    end

    {:ok, modules} = :application.get_key(app, :modules)

    ctx_filter =
      if root == nil do
        fn _ -> true end
      else
        root = to_string(root)
        fn m -> String.starts_with?(to_string(m), root) end
      end

    modules
    |> Stream.filter(ctx_filter)
    |> Stream.filter(fn m -> function_exported?(m, :components, 0) end)
    |> Stream.flat_map(fn m -> m.components end)
  end
end
