defmodule CroniqWeb.Pagination do
  @moduledoc """
  Provides pagination utilities for controllers.
  Handles parsing, validation and calculation of pagination parameters.
  """
  def parse_params(params) do
    page = get_integer(params, "page", 1)
    page_size = get_integer(params, "page_size", 10) |> min(100)
    {page, page_size}
  end

  def parse_params(params, total_pages) do
    {page, page_size} = parse_params(params)
    page = min(page, total_pages)
    {page, page_size}
  end

  def total(base_query) do
    Croniq.Repo.aggregate(base_query, :count, :id)
  end

  def total_pages(total_records, page_size) do
    div(total_records + page_size - 1, page_size) |> max(1)
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
    if value < 1 do
      default
    else
      value
    end
  end
end
