defmodule CroniqWeb.Pagination do
  def parse_params(params) do
    page = get_integer(params, "page", 1)
    page_size = get_integer(params, "page_size", 10) |> min(100)
    {page, page_size}
  end

  def total(base_query) do
    Croniq.Repo.aggregate(base_query, :count, :id)
  end

  def total_pages(total_records, page_size) do
    div(total_records + page_size - 1, page_size)
  end

  def offset(page, page_size) do
    (page - 1) * page_size
  end

  defp get_integer(params, key, default) do
    case Map.get(params, key) do
      nil ->
        default

      value when is_binary(value) ->
        valid(String.to_integer(value), default)

      value when is_integer(value) ->
        valid(value, default)
    end
  end

  defp valid(value, default) do
    cond do
      value < 1 -> default
      true -> value
    end
  end
end
