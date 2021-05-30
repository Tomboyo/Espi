defmodule Espi do
  require Logger

  defmodule Component do
    @type t :: %__MODULE__{
            module: module,
            opts: keyword,
            callback: {module, atom}
          }
    defstruct [:module, :opts, :callback]
  end

  # https://elixirforum.com/t/nicest-way-to-emulate-function-decorators/2050/26
  defmacro __using__(_) do
    quote do
      @on_definition Espi.CompileHooks
      @before_compile Espi.CompileHooks
      @components []

      @component nil
    end
  end

  defmodule CompileHooks do
    def __on_definition__(env, kind, fun, args, _guards, _body) do
      component = Module.get_attribute(env.module, :component)

      if is_nil(component) do
        # This funciton is not a @component
        :ok
      else
        {:ok, module, opts} = validate!(component, kind, {env.module, fun, length(args)})

        # Resolve a possibly-aliased component module
        module =
          env.aliases
          |> Stream.filter(fn {alias, _} -> module == alias end)
          |> Stream.map(fn {_, mod} -> mod end)
          |> Enum.at(0, module)

        component = %Component{
          module: module,
          opts: opts,
          callback: {env.module, fun}
        }

        components = Module.get_attribute(env.module, :components)
        components = [component | components]
        Module.put_attribute(env.module, :components, components)
        Module.put_attribute(env.module, :component, nil)
        :ok
      end
    end

    defp validate!(component, kind, context) do
      with(
        {1, :def} <- {1, kind},
        {2, {mod, opts}} when is_atom(mod) and is_list(opts) <- {2, component}
      ) do
        {:ok, mod, opts}
      else
        {1, _} ->
          raise bad_component("Only a public function may be a @component", context)

        {2, _} ->
          raise bad_component("Component syntax is `@component {Module, Keyword}`", context)
      end
    end

    defp bad_component(reason, {m, f, a}) do
      "Invalid component specification at #{m}.#{f}/#{a}: #{reason}"
    end

    defmacro __before_compile__(_env) do
      quote do
        def components, do: @components
      end
    end
  end

  defmodule App do
    use Application

    @impl true
    def start(_type, _args) do
      app = Application.fetch_env!(:espi, :application)
      namespace = Application.fetch_env!(:espi, :namespace)

      children = scan(app, namespace)

      Logger.info(
        "Starting #{length(children)} components in app '#{app}' under namespace '#{namespace}'"
      )

      Logger.debug("Components: #{inspect(children)}")

      Supervisor.start_link(children, strategy: :one_for_one)
    end

    def scan(app, namespace) do
      {:ok, modules} = :application.get_key(app, :modules)

      modules
      |> Stream.filter(namespace_filter(namespace))
      |> Enum.filter(&has_components?/1)
      |> Enum.flat_map(fn m -> m.components end)
      |> Enum.map(&to_child/1)
    end

    defp namespace_filter(namespace) do
      if namespace == nil do
        fn _ -> true end
      else
        namespace = to_string(namespace)
        fn m -> String.starts_with?(to_string(m), namespace) end
      end
    end

    defp has_components?(module) do
      # make sure modules are loaded to handle :interactive mode
      with {:module, module} <- Code.ensure_loaded(module) do
        function_exported?(module, :components, 0)
      else
        e -> raise "Could not load module: #{inspect(e)}"
      end
    end

    def to_child(component = %Component{}) do
      {m, f} = component.callback

      %{
        id: "Component(#{component.module}, #{m}.#{f}/1)",
        start:
          {component.module, :start_link, [[{:callback, component.callback} | component.opts]]}
      }
    end
  end
end
