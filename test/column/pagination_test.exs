defmodule Column.PaginationTest do
  use ExUnit.Case, async: true

  alias Column.Pagination

  describe "build_params/1" do
    test "accepts valid params" do
      assert {:ok, params} = Pagination.build_params(limit: 50, starting_after: "id_123")
      assert params["limit"] == 50
      assert params["starting_after"] == "id_123"
    end

    test "rejects both cursor params" do
      assert {:error, msg} =
               Pagination.build_params(
                 starting_after: "id_a",
                 ending_before: "id_b"
               )

      assert msg =~ "mutually exclusive"
    end

    test "rejects out-of-range limit" do
      assert {:error, _} = Pagination.build_params(limit: 0)
      assert {:error, _} = Pagination.build_params(limit: 101)
    end

    test "accepts limit 1 and 100" do
      assert {:ok, _} = Pagination.build_params(limit: 1)
      assert {:ok, _} = Pagination.build_params(limit: 100)
    end
  end

  describe "fetch_all/2" do
    test "collects all pages into a flat list" do
      page1 = %{"data" => [%{"id" => "a"}, %{"id" => "b"}], "has_more" => true}
      page2 = %{"data" => [%{"id" => "c"}], "has_more" => false}

      call_count = :counters.new(1, [])

      list_fn = fn opts ->
        :counters.add(call_count, 1, 1)
        n = :counters.get(call_count, 1)
        cursor = opts[:starting_after]

        cond do
          n == 1 && is_nil(cursor) -> {:ok, page1}
          n == 2 && cursor == "b" -> {:ok, page2}
          true -> {:error, %Column.Error{type: :api_error, message: "unexpected call"}}
        end
      end

      assert {:ok, items} = Pagination.fetch_all(list_fn)
      assert length(items) == 3
      assert Enum.map(items, & &1["id"]) == ["a", "b", "c"]
    end
  end
end
