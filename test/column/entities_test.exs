defmodule Column.EntitiesTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "create_person/2" do
    test "creates a person entity", %{bypass: bypass, config: config} do
      person = Fixtures.entity_person()
      stub_json(bypass, "POST", "/entities/person", 200, person)

      assert {:ok, result} =
               Column.Entities.create_person(
                 %{
                   first_name: "Ada",
                   last_name: "Lovelace"
                 },
                 config: config
               )

      assert result["id"] == "ent_person123"
      assert result["type"] == "person"
    end
  end

  describe "create_business/2" do
    test "creates a business entity", %{bypass: bypass, config: config} do
      biz = Fixtures.entity_business()
      stub_json(bypass, "POST", "/entities/business", 200, biz)

      assert {:ok, result} =
               Column.Entities.create_business(
                 %{
                   business_name: "Acme Corp"
                 },
                 config: config
               )

      assert result["id"] == "ent_biz123"
    end
  end

  describe "get/2" do
    test "gets an entity", %{bypass: bypass, config: config} do
      person = Fixtures.entity_person()
      stub_json(bypass, "GET", "/entities/ent_person123", 200, person)

      assert {:ok, result} = Column.Entities.get("ent_person123", config: config)
      assert result["kyc_status"] == "APPROVED"
    end
  end

  describe "get_compliance/2" do
    test "gets compliance status", %{bypass: bypass, config: config} do
      compliance = %{"kyc_status" => "APPROVED", "reasons" => []}
      stub_json(bypass, "GET", "/entities/ent_person123/compliance", 200, compliance)

      assert {:ok, result} = Column.Entities.get_compliance("ent_person123", config: config)
      assert result["kyc_status"] == "APPROVED"
    end
  end

  describe "list_associated_persons/2" do
    test "lists beneficial owners", %{bypass: bypass, config: config} do
      owners = Fixtures.list_response([Fixtures.entity_person()])
      stub_json(bypass, "GET", "/entities/ent_biz123/associated-persons", 200, owners)

      assert {:ok, result} = Column.Entities.list_associated_persons("ent_biz123", config: config)
      assert length(result["data"]) == 1
    end
  end
end
