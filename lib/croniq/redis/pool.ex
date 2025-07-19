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

defmodule Croniq.Redis.Pool do
  @moduledoc """
  Redis connection pool based on poolboy for asynchronous access to Redis via Redix.
  Use Croniq.Redis.Pool.command/1 to execute Redis commands with automatic connection management.
  """
  @pool_name :redix_pool

  def child_spec(_args) do
    :poolboy.child_spec(
      @pool_name,
      [
        name: {:local, @pool_name},
        worker_module: Redix,
        size: Application.get_env(:croniq, :redis_pool)[:pool_size],
        max_overflow: 0
      ],
      Application.get_env(:croniq, :redix)[:url]
    )
  end

  def command(command) do
    :poolboy.transaction(@pool_name, fn conn ->
      Redix.command(conn, command)
    end)
  end
end
