defmodule CodeCorps.GitHub.Adapters.GithubRepo do

  @mapping [
    {:github_id, ["id"]},
    {:name, ["name"]},
    {:github_account_id, ["owner", "id"]},
    {:github_account_avatar_url, ["owner", "avatar_url"]},
    {:github_account_login, ["owner", "login"]},
    {:github_account_type, ["owner", "type"]}
  ]

  @spec from_api(map) :: map
  def from_api(%{} = payload) do
    payload |> CodeCorps.Adapter.MapTransformer.transform(@mapping)
  end
end
