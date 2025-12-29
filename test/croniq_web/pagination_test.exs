# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.PaginationTest do
  use CroniqWeb.ConnCase, async: true

  describe "parse_params/1" do
    test "simple" do
      {page, page_size} = CroniqWeb.Pagination.parse_params(%{"page" => "8", "page_size" => "17"})

      assert page == 8
      assert page_size == 17
    end

    test "default" do
      {page, page_size} = CroniqWeb.Pagination.parse_params(%{})

      assert page == 1
      assert page_size == 10
    end

    test "negative" do
      {page, page_size} =
        CroniqWeb.Pagination.parse_params(%{"page" => "-2", "page_size" => "-15"})

      assert page == 1
      assert page_size == 10
    end

    test "page size limit" do
      {page, page_size} =
        CroniqWeb.Pagination.parse_params(%{"page" => "8", "page_size" => "1000"})

      assert page == 8
      assert page_size == 100
    end
  end

  describe "parse_params/2" do
    test "simple" do
      {page, page_size} =
        CroniqWeb.Pagination.parse_params(%{"page" => "8", "page_size" => "17"}, 5)

      assert page == 5
      assert page_size == 17
    end
  end

  describe "total_pages/2" do
    test "total" do
      total = CroniqWeb.Pagination.total_pages(0, 15)
      assert total == 1
    end
  end
end
