require 'test_helper'

describe IronHide::Storage::FileAdapter do
  describe "when using FileAdapter" do
    def setup
      IronHide.config do |config|
        config.adapter = :file
        config.json    = File.join('test','rules.json')
      end
      @storage = IronHide.storage
    end


    def teardown
      IronHide.reset
    end
    describe "#adapter" do
      it "returns a FileAdapter" do
        assert_instance_of IronHide::Storage::FileAdapter, @storage.adapter
      end
    end

    describe "#where" do
      # Examples are stored in spec/rules.json
      let(:example1) do
        [
          {
            "resource" => "com::test::Resource",
            "action" => [ "read", "update" ],
            "description" => "Read/update access for Resource.",
            "effect"      => "allow",
            "conditions"  => [
              {"equal"=>{"user::user_role_ids"=>["1", "2"]}}
            ]
          },
          {
            "resource" => "com::test::Resource",
            "action" => [ "read" ],
            "description" => "Read access for Resource.",
            "effect"      => "deny",
            "conditions"  => [
              {"equal"=>{"user::user_role_ids"=>["5"]}}
            ]
          }
        ]
      end

      describe "example1" do
        it "returns all the JSON rules for a specified action/resource" do
          json = @storage.where(
            resource: "com::test::Resource",
            action: "read")

          assert_equal example1, json, "#{IronHide.storage.adapter.rules}"
        end
      end

      let(:example2) do
        [
          {
            "resource" => "com::test::Resource",
            "action" => [ "read", "update" ],
            "description" => "Read/update access for Resource.",
            "effect"      => "allow",
            "conditions"  => [
              {"equal"=>{"user::user_role_ids"=>["1", "2"]}}
            ]
          }
        ]
      end
      describe "example2" do
        it "returns all the JSON rules for a specified action/resource" do
          json = @storage.where(
            resource: "com::test::Resource",
            action: "update")

          assert_equal example2, json, "#{IronHide.storage.adapter.rules}"
        end
      end

      let(:example3) do
        [
          {
            "resource" => "com::test::Resource",
            "action"=> [ "delete" ],
            "description"=> "Delete access for Resource",
            "effect"=> "allow",
            "conditions"=> [
              {
                "equal"=> {
                  "user::user_role_ids"=> ["1"]
                }
              }
            ]
          }
        ]
      end
      describe "example3" do
        it "returns all the JSON rules for a specified action/resource" do
          json = @storage.where(
            resource: "com::test::Resource",
            action: "delete")

          assert_equal example3, json, "#{IronHide.storage.adapter.rules}"
        end
      end
    end
  end
end
