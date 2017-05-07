defmodule CodeCorps.Github do

  alias CodeCorps.{User, Repo}

  @doc """
  Temporary function until the actual behavior is implemented.
  """
  def connect(user, _code), do: {:ok, user}

  def associate(user, params) do
    user
    |> User.github_associate_changeset(params)
    |> Repo.update()
  end

  def create_issue(attributes, project, current_user) do
    access_token = current_user.github_access_token || default_user_token() # need to create the Github user for this token
    client = Tentacat.Client.new(%{access_token: access_token})
    response = Tentacat.Issues.create(
      project.github_owner,
      project.github_repo,
      issue_attributes(attributes),
      client
    )
    case response.status do
      201 ->
        response.body["id"] # return the github id
      _ ->
        # log error
        nil
    end
  end

  defp issue_attributes(attributes) do
    %{
      title: attributes[:title],
      body: attributes[:body]
    }
  end

  defp default_user_token do
    System.get_env("GITHUB_DEFAULT_USER_TOKEN")
  end
end
