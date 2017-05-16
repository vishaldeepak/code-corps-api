defmodule CodeCorps.Services.TaskServiceTest do
  use CodeCorps.ApiCase, resource_name: :task

  alias CodeCorps.Services.TaskService

  @valid_attrs %{
    "title" => "Test task",
    "markdown" => "A test task",
    "status" => "open"
  }

  @invalid_attrs %{
    "title" => nil,
    "status" => "nonexistent"
  }

  describe "create_task/2" do
    @tag :authenticated
    test "Github module is called to create issue when project is connected to github", %{conn: conn, current_user: current_user} do
      project = insert(:project, github_id: 1)
      task_list = insert(:task_list, project: project)
      attrs = @valid_attrs |> Map.merge(%{"project_id" => project.id, "user_id" => current_user.id, "task_list_id" => task_list.id})
      {_ok, task} = TaskService.create_task(conn, attrs)
      task_id = task.id

      assert task.github_id == 1
      assert_received {:create_issue, ^task_id}
    end

    @tag :authenticated
    test "Github module is NOT called to create issue when project is NOT connected to github", %{conn: conn, current_user: current_user} do
      project = insert(:project, github_id: nil)
      task_list = insert(:task_list, project: project)
      attrs = @valid_attrs |> Map.merge(%{"project_id" => project.id, "user_id" => current_user.id, "task_list_id" => task_list.id})
      {_ok, task} = TaskService.create_task(conn, attrs)

      assert task.github_id == nil
      refute_received {:create_issue, _task_id}
    end

    @tag :authenticated
    test "it returns error when invalid task attributes and doesnt call the Github module", %{conn: conn, current_user: current_user} do
      project = insert(:project, github_id: 1)
      task_list = insert(:task_list, project: project)
      attrs = @invalid_attrs |> Map.merge(%{"project_id" => project.id, "user_id" => current_user.id, "task_list_id" => task_list.id})
      {_error, changeset} = TaskService.create_task(conn, attrs)

      assert changeset.valid? == false
      refute_received {:create_issue, _task_id}
    end
  end
end
