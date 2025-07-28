# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

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

    # test "from parse_params/1" do
    #   {page, page_size} = CroniqWeb.Pagination.parse_params(1, 10)
    # end
  end

  describe "total_pages/2" do
    test "total" do
      total = CroniqWeb.Pagination.total_pages(0, 15)
      assert total == 1
    end
  end
end
