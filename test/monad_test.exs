require Monad

defmodule Monad.Test do
  alias Monad, as: M
  use ExUnit.Case 

  test "identity monad" do
    f = fn() ->
      M.identity do
        a = 1
        b = a + 1
      end
    end
    assert f.() == 2
  end

  test "error monad with no error" do
    f = fn() ->
      M.error do
        file = "/etc/passwd"
        {:ok, bin} = :file.read_file(file)
        bin
      end
    end
    assert is_binary(f.())
  end

  test "error monad with an error" do
    f = fn() ->
      M.error do
        file = "/etc/passwd-does-not-exist"
        {:ok, bin} = :file.read_file(file)
        bin
      end
    end
    assert f.() == {:error, :enoent}
  end

  test "list monad" do
    f = fn() ->
      M.list do
        a = 1
        a = a + 1
        a = a + 1
      end
    end
    assert f.() == [1,2,3]
  end

end