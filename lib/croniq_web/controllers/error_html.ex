defmodule CroniqWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use CroniqWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/croniq_web/controllers/error_html/404.html.heex
  #   * lib/croniq_web/controllers/error_html/500.html.heex
  #
  embed_templates "error_html/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".

  def render("404.html", _assigns) do
    render("404.html", %{})
  end

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
