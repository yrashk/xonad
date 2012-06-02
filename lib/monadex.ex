defmodule Monad.Implementation do

  def with(module, block) do
      module.__with__(block)
  end 

  def monad([{:do, {:__block__, _line, block}}], module) do
    body = Enum.reduce block, module.empty, 
                       fn(expr, acc) ->
                         module.bind(expr, module.return(acc))
                       end
    quote do: (    
      try do
        unquote(body)
      catch type, error -> unquote(module).exception(type, error) 
      end)
  end

  def monad([{:do, block}], module) do
    monad([{:do, {:__block__, 0, [block]}}], module)
  end


  defmacro __using__(_) do
    quote do
     def __with__(block) do
       Monad.Implementation.monad(block, unquote(__CALLER__.module))
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
    def empty do
      nil
    end
    def exception(_,e), do: throw(e)
  end 
  defmacro identity(block), do: with(Identity, block)

  defmodule Error do
    use Monad.Implementation

    def return(x) do
     quote do: (
        case unquote(x) do
          :ok -> {:ok, nil}
          :error -> {:error, nil}
          {:ok, _} = ok -> 
            ok
         {:error, _} = error -> error
          x -> {:ok, x}
        end)
    end
    def bind(block, result) do
      quote do: (
        case unquote(result) do
          :ok -> unquote(block)
          {:ok, _} -> 
            unquote(block)
          {:error, _} = error -> throw({:badmatch, error})
        end)
    end
    def empty do
      quote do: {:ok, nil}
    end
    def exception(_,{:badmatch, {:error, _} = error}), do: error
    def exception(_,e), do: throw(e)
  end
  defmacro error(block), do: with(Error, block)

end
