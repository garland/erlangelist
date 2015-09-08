defmodule Erlangelist.Article do
  @external_resource "articles/index.exs"

  {articles_meta, _} = Code.eval_file("articles/index.exs")

  for {article_id, _} <- articles_meta do
    @external_resource "articles/#{article_id}.md"
  end

  transform_meta = fn({article_id, meta}) ->
    transformed_meta =
      meta
      |> Enum.map(fn
        {:posted_at, isodate} ->
          {:ok, date} = Timex.DateFormat.parse(isodate, "{ISOdate}")
          {:ok, formatted_date} = Timex.DateFormat.format(date, "%B %d, %Y", :strftime)
          {:posted_at, formatted_date}

        {:redirect, old_link} ->
          {:redirect, "http://theerlangelist.blogspot.com#{old_link}"}

        other -> other
      end)

    {article_id, transformed_meta}
  end

  def all do
    unquote(Enum.map(articles_meta, transform_meta))
  end


  [{article_id, _} | _] = articles_meta
  def most_recent do
    unquote(article_id)
  end

  for {article_id, meta} <- articles_meta do
    def meta(unquote(article_id)) do
      unquote(meta)
    end
  end

  def meta(_), do: nil


  html = fn(article_id) ->
    "articles/#{article_id}.md"
    |> File.read!
    |> Earmark.to_html
  end

  for {article_id, meta} <- articles_meta, meta[:redirect] == nil do
    def html(unquote(article_id)) do
      unquote(html.(article_id))
    end
  end

  def html(_), do: nil

  def link({article_id, meta}) do
    meta[:redirect] || "/article/#{article_id}"
  end

  def title({_, meta}), do: meta[:title]
end