defmodule Xonad.Implementation do

  def with(module, block, opts // []) do
      module.__with__(block, opts)
  end 

  def xonad([{:do, {:__block__, _line, block}}], module, opts) do
    {:do, body} = Enum.reduce block, {:start, module.empty(opts)}, 
                       (fn do
                         expr, {:start, acc} ->
                           {:do, module.bind(expr, acc)}
                         expr, {:do, acc} ->
                           {:do, module.bind(expr, module.return(acc))}
                       end)
    quote do 
      try do
        m = unquote(body)
        unquote(module).then(m)
      catch type, error -> unquote(module).exception(unquote(module), type, error) 
      end
    end
  end

  def xonad([{:do, block}], module, opts) do
    xonad([{:do, {:__block__, 0, [block]}}], module, opts)
  end

  defmacro __using__(_) do
    quote do
     def __with__(block, opts) do
       Xonad.Implementation.xonad(block, unquote(__CALLER__.module), opts)
     end

     def then(r), do: r
 
     def exception(m, _,{:badmatch, {:error, _} = error}), do: m.fail(error)
     def exception(_, _, e), do: throw(e)

     def fail(v), do: throw({:badmatch, v})

     defoverridable [then: 1, exception: 3, fail: 1]
    end
  end
end

defmodule Xonad do
  import Xonad.Implementation

  defmodule Identity do
    use Xonad.Implementation
    def return(x) do
      x
    end
    def bind(block, result) do
      quote do
        unquote(result)
        unquote(block)
      end
    end
    def empty(_) do
      nil
    end
  end 
  defmacro identity(block), do: with(Identity, block)

  defmodule List do
    use Xonad.Implementation

    def return(x) do
      quote do: [unquote(x)]
    end
    def bind(block, result) do
      quote do
        _tail = unquote(result)
        _v = unquote(block)
        [_v|_tail]
      end
    end
    def empty(_) do
      quote do: []
    end
    def then([h|t]) do
        List.concat(lc i inlist t, do: then(i)) ++ [h]
    end
  end 
  defmacro list(block), do: with(List, block)

  defmodule Error do
    use Xonad.Implementation

    def return(x) do
     quote do
        case unquote(x) do
          :ok -> {:ok, nil}
          :error -> {:error, nil}
          {:ok, _} = ok -> ok
          {:error, _} = error -> error
          x -> {:ok, x}
        end
     end
    end
    def bind(block, result) do
      quote do
        case unquote(result) do
          :ok -> unquote(block)
          {:ok, _} -> unquote(block)
          {:error, _} = error -> throw({:badmatch, error})
        end
      end
    end
    def empty(_) do
      quote do: {:ok, nil}
    end

    def fail(v), do: v

    def exception(_, _, {:badmatch, _}), do: super
    def exception(_, _, e), do: {:error, e}

  end

  defmacro error(block), do: with(Error, block)

end
