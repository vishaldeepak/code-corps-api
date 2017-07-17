defmodule CodeCorps.GitHub.Event.InstallationTest do
  @moduledoc false

  use CodeCorps.{DbAccessCase, GitHubCase}

  import CodeCorps.{Factories, TestHelpers.GitHub}

  alias CodeCorps.{
    GithubAppInstallation,
    GithubRepo,
    GitHub.Event.Installation,
    Repo
  }

  @access_token "v1.1f699f1069f60xxx"
  @expires_at Timex.now() |> Timex.shift(hours: 1) |> DateTime.to_iso8601()
  @access_token_create_response %{"token" => @access_token, "expires_at" => @expires_at}

  @installation_created load_event_fixture("installation_created")
  @installation_repositories load_endpoint_fixture("installation_repositories")

  describe "handle/2" do
    test "returns error if payload is wrong" do
      event = build(:github_event, action: "created", type: "installation")
      assert {:error, :unexpected_action_or_payload} == Installation.handle(event, %{})
    end

    test "returns error if action of the event is wrong" do
      event = build(:github_event, action: "foo", type: "installation")
      assert {:error, :unexpected_action_or_payload} == Installation.handle(event, @installation_created)
    end

    test "returns error if user payload is wrong" do
      event = build(:github_event, action: "created", type: "installation")
      assert {:error, :unexpected_action_or_payload} == Installation.handle(event, @installation_created |> Map.put("sender", "foo"))
    end

    test "returns error if installation payload is wrong" do
      event = build(:github_event, action: "created", type: "installation")
      assert {:error, :unexpected_action_or_payload} == Installation.handle(event, @installation_created |> Map.put("installation", "foo"))
    end
  end

  describe "handle/2 for Installation::created" do
    @tag bypass: %{
      "/installation/repositories" => {200, @installation_repositories},
      "/installations/#{@installation_created["installation"]["id"]}/access_tokens" => {200, @access_token_create_response}
    }
    test "creates installation for unmatched user if no user, syncs repos" do
      payload = %{"installation" => %{"id" => installation_github_id}} = @installation_created
      event = build(:github_event, action: "created", type: "installation")

      {:ok, %GithubAppInstallation{} = installation, %Task{} = task}
        = Installation.handle(event, payload)

      assert installation.github_id == installation_github_id
      assert installation.origin == "github"
      assert installation.state == "processing"
      refute installation.user_id
      assert installation.installed == true

      task |> Task.await

      assert Repo.aggregate(GithubRepo, :count, :id) == 2
      assert Repo.one(GithubAppInstallation).state == "processed"
    end

    @tag bypass: %{
      "/installation/repositories" => {200, @installation_repositories},
      "/installations/#{@installation_created["installation"]["id"]}/access_tokens" => {200, @access_token_create_response}
    }
    test "creates installation if user matched but installation unmatched, syncs repos" do
      %{"sender" => %{"id" => user_github_id}} = payload = @installation_created
      event = build(:github_event, action: "created", type: "installation")

      user = insert(:user, github_id: user_github_id)

      {:ok, %GithubAppInstallation{} = installation, %Task{} = task}
        = Installation.handle(event, payload)

      assert installation.github_id == (payload |> get_in(["installation", "id"]))
      assert installation.origin == "github"
      assert installation.state == "processing"
      assert installation.user_id == user.id
      assert installation.installed == true

      task |> Task.await

      assert Repo.aggregate(GithubRepo, :count, :id) == 2
      assert Repo.one(GithubAppInstallation).state == "processed"
    end

    @tag bypass: %{
      "/installation/repositories" => {200, @installation_repositories},
      "/installations/#{@installation_created["installation"]["id"]}/access_tokens" => {200, @access_token_create_response}
    }
    test "updates installation, if both user and installation matched, syncs repos" do
      %{"sender" => %{"id" => user_github_id}, "installation" => %{"id" => installation_github_id}} = payload = @installation_created
      event = build(:github_event, action: "created", type: "installation")

      user = insert(:user, github_id: user_github_id)
      insert(
        :github_app_installation,
        user: user,
        access_token_expires_at: Timex.now |> Timex.shift(days: 1)
      )

      {:ok, %GithubAppInstallation{} = installation, %Task{} = task}
        = Installation.handle(event, payload)

      assert installation.origin == "codecorps"
      assert installation.state == "processing"
      assert installation.user_id == user.id
      assert installation.github_id == installation_github_id
      assert installation.installed == true

      task |> Task.await

      assert Repo.aggregate(GithubRepo, :count, :id) == 2
      assert Repo.one(GithubAppInstallation).state == "processed"
    end

    @tag bypass: %{
      "/installation/repositories" => {200, @installation_repositories},
      "/installations/#{@installation_created["installation"]["id"]}/access_tokens" => {200, @access_token_create_response}
    }
    test "updates installation if there is an installation, but no user, syncs repos" do
      %{"installation" => %{"id" => installation_github_id}, "sender" => %{"id" => sender_github_id}} = payload = @installation_created
      insert(:github_app_installation, github_id: installation_github_id)
      event = build(:github_event, action: "created", type: "installation")

      {:ok, %GithubAppInstallation{} = installation, %Task{} = task}
        = Installation.handle(event, payload)

      assert installation.origin == "codecorps"
      assert installation.state == "processing"
      assert installation.sender_github_id == sender_github_id

      task |> Task.await

      assert Repo.aggregate(GithubRepo, :count, :id) == 2
      assert Repo.one(GithubAppInstallation).state == "processed"
    end
  end
end
