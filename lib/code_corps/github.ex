defmodule CodeCorps.GitHub do
  alias CodeCorps.{User, Repo}
  require Logger

  @api Application.get_env(:code_corps, :github_api)

  @doc """
  POSTs `code` to GitHub to receive an OAuth token, then associates the user
  with that OAuth token.

  Accepts a third parameter – a custom API module – for the purposes of
  explicit dependency injection during testing.

  Returns one of the following:

  - `{:ok, %CodeCorps.User{}}`
  - `{:error, %Ecto.Changeset{}}`
  - `{:error, "some_github_error"}`
  """
  @spec connect(User.t, String.t, module) :: {:ok, User.t} | {:error, String.t}
  def connect(%User{} = user, code, api \\ @api) do
    case code |> api.connect do
      {:ok, github_auth_token} -> user |> associate(%{github_auth_token: github_auth_token})
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Associates user with the GitHub OAuth token.

  Returns one of the following:

  - {:ok, %CodeCorps.User{}}
  - {:error, %Ecto.Changeset{}}
  """
  @spec associate(User.t, map) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def associate(user, params) do
    user
    |> User.github_association_changeset(params)
    |> Repo.update()
  end

  def create_issue(project, attributes, current_user) do
    access_token = current_user.github_access_token || default_user_token() # need to create the Github user for this token
    client = Tentacat.Client.new(%{access_token: access_token})
    response = Tentacat.Issues.create(
      project.github_owner,
      project.github_repo,
      attributes,
      client
    )
    case response.status do
      201 ->
        response.body["id"] # return the github id
      _ ->
        Logger.error "Could not create task for Project ID: #{project.id}. Error: #{response.body}"
    end
  end

  defp default_user_token do
    System.get_env("GITHUB_DEFAULT_USER_TOKEN")
  end
end
