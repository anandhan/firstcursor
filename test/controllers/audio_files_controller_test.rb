require "test_helper"

class AudioFilesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get audio_files_index_url
    assert_response :success
  end

  test "should get parse" do
    get audio_files_parse_url
    assert_response :success
  end

  test "should get update_metadata" do
    get audio_files_update_metadata_url
    assert_response :success
  end
end
