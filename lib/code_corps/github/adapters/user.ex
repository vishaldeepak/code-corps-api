defmodule CodeCorps.GitHub.Adapters.User do
  @moduledoc """
  Used to adapt a GitHub issue payload into attributes for creating or updating
  a `CodeCorps.Task`.
  """

  @mapping [
    {:github_username, ["login"]},
    {:github_id, ["id"]},
    {:github_avatar_url, ["avatar_url"]}
  ]

  @spec from_github_user(map) :: map
  def from_github_user(%{} = payload) do
    payload |> CodeCorps.Adapter.MapTransformer.transform(@mapping)
  end
end
