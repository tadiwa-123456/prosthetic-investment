require "test_helper"

class MachinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @machine = machines(:one)
  end

  test "should get index" do
    get machines_url
    assert_response :success
  end

  test "should get new" do
    get new_machine_url
    assert_response :success
  end

  test "should create machine" do
    assert_difference("Machine.count") do
      post machines_url, params: { machine: { annual_maintenance_cost: @machine.annual_maintenance_cost, build_volume_x: @machine.build_volume_x, build_volume_y: @machine.build_volume_y, build_volume_z: @machine.build_volume_z, laser_power: @machine.laser_power, lifespan_years: @machine.lifespan_years, model_number: @machine.model_number, name: @machine.name, purchase_price: @machine.purchase_price } }
    end

    assert_redirected_to machine_url(Machine.last)
  end

  test "should show machine" do
    get machine_url(@machine)
    assert_response :success
  end

  test "should get edit" do
    get edit_machine_url(@machine)
    assert_response :success
  end

  test "should update machine" do
    patch machine_url(@machine), params: { machine: { annual_maintenance_cost: @machine.annual_maintenance_cost, build_volume_x: @machine.build_volume_x, build_volume_y: @machine.build_volume_y, build_volume_z: @machine.build_volume_z, laser_power: @machine.laser_power, lifespan_years: @machine.lifespan_years, model_number: @machine.model_number, name: @machine.name, purchase_price: @machine.purchase_price } }
    assert_redirected_to machine_url(@machine)
  end

  test "should destroy machine" do
    assert_difference("Machine.count", -1) do
      delete machine_url(@machine)
    end

    assert_redirected_to machines_url
  end
end
