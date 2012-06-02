defmodule Monad.Implementation do

  def with(module, block, opts // []) do
      module.__with__(block, opts)
  end 

  def monad([{:do, {:__block__, _line, block}}], module, opts) do
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
      catch type, error -> unquote(module).exception(type, error) 
      end
    end
  end

  def monad([{:do, block}], module, opts) do
    monad([{:do, {:__block__, 0, [block]}}], module, opts)
  end

  defmacro __using__(_) do
    quote do
     def __with__(block, opts) do
       Monad.Implementation.monad(block, unquote(__CALLER__.module), opts)
     end
    end
  end
end

defmodule Monad do
  import Monad.Implementation

  defmodule Identity do
    use Monad.Implementation
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
    def then(results), do: results
    def exception(_,e), do: throw(e)
  end 
  defmacro identity(block), do: with(Identity, block)

  defmodule List do
    use Monad.Implementation

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
        List.concat(lc i in t, do: then(i)) ++ [h]
    end
    def then(v), do: v

    def exception(_,e), do: throw(e)
  end 
  defmacro list(block), do: with(List, block)

  defmodule Error do
    use Monad.Implementation

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
    def then(results), do: results
    def exception(_,{:badmatch, {:error, _} = error}), do: error
    def exception(_,e), do: throw(e)
  end

  defmacro error(block), do: with(Error, block)

end
