require Xonad

defmodule Xonad.Test do
  alias Xonad, as: X
  use ExUnit.Case 

  test "identity xonad" do
    f = fn() ->
      X.identity do
        a = 1
        b = a + 1
      end
    end
    assert f.() == 2
  end

  test "error xonad with no error" do
    f = fn() ->
      X.error do
        file = "test/xonad_test.exs"
        {:ok, bin} = :file.read_file(file)
        bin
      end
    end
    assert is_binary(f.())
  end

  test "error xonad with an error" do
    f = fn() ->
      X.error do
        file = "/etc/passwd-does-not-exist"
        :file.read_file(file)
        :done
      end
    end
    assert f.() == {:error, :enoent}
  end

  test "error xonad with a badmatch error" do
    f = fn() ->
      X.error do
        file = "/etc/passwd-does-not-exist"
        {:ok, bin} = :file.read_file(file)
        bin
      end
    end
    assert f.() == {:error, :enoent}
  end

  test "error xonad with an exception" do
    f = fn() ->
      X.error do
        file = "/etc/passwd-does-not-exist"
        {:ok, bin} = throw(:unexpected)
        bin
      end
    end
    assert f.() == {:error, :unexpected}
  end

  test "list xonad" do
    f = fn() ->
      X.list do
        a = 1
        a = a + 1
        a = a + 1
      end
    end
    assert f.() == [1,2,3]
  end

  ##

  test "xonad inside a xonad" do
    f = fn() ->
      X.identity do
        X.error do
          1
          {:ok, _} = :file.read_file("does_not_exist")
        end
      end
    end
    assert f.() == {:error, :enoent}
  end

  test "xonad failure" do
   f = fn() ->
     X.identity do
       1 = (fn() -> 2 end).()
     end
   end
   assert_throw {:badmatch, 2}, f
  end

 end
