require "mod-gui"

DEBUG = false
CAMERA_TOGGLE_BUTTON = "camera_toggle"
TARGET_BUTTONS_PREFIX = "button_camera_target_"


-- Events --

script.on_init(function(event)
  global.show = {}
  global.target = {}
end)

-- Update GUI if mod or settings have been updated
script.on_configuration_changed(function(event)
  for index, player in pairs(game.players) do
    if player.connected and global.show[index] then
      destroy_camera_frame(player)
      create_camera_frame(player)
    end
  end
end)

-- Init a player's ui
script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]

  create_show_toggle_button(player)
end)

-- Update all guis when a player joins
script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.players[event.player_index]

  -- Remove the camera frame so it gets refreshed
  set_show_state(player, false)

  -- Show camera by default
  set_show_state(player, true)

  -- Add button for the player for all current players
  for _,other_player in pairs(game.players) do
    if other_player.connected and other_player ~= player then
      add_target_button(other_player, player)
    end
  end
end)

-- Update all guis when a player leaves
script.on_event(defines.events.on_player_left_game, function(event)
  local player = game.players[event.player_index]

  -- Remove the target button from all players
  for _,other_player in pairs(game.players) do
    if other_player.connected and other_player ~= player then
      remove_target_button(other_player, player)

      if get_target_for(other_player) == player then
        set_target_for(other_player, other_player)
      end
    end
  end
end)

-- Handle button clicks
script.on_event(defines.events.on_gui_click, function(event)
  local clicker = game.players[event.player_index]
  local element_name = event.element.name
  -- Clicked element is a player target button
  if element_name:sub(1, #TARGET_BUTTONS_PREFIX) == TARGET_BUTTONS_PREFIX then
    local target_name = element_name:sub(#TARGET_BUTTONS_PREFIX + 1)
    set_target_for(clicker, game.get_player(target_name))
  -- Clicked on camera toggle button
  elseif element_name == CAMERA_TOGGLE_BUTTON then
    set_show_state(clicker, not get_show_state(clicker))
  end
end)

-- Update camera loop
script.on_event(defines.events.on_tick, function(event)
  update_camera_element()
end)


-- Functions --


function get_show_state(player)
  return global.show[player.index]
end

function set_show_state(player, state)
  if get_show_state(player) ~= state then
    global.show[player.index] = state

    if get_show_state(player) then
      create_camera_frame(player)
    else
      destroy_camera_frame(player)
    end
  end
end

function get_target_for(player)
  local previous_target_index = global.target[player.index]
  if previous_target_index then
    return game.players[previous_target_index]
  else
    return nil
  end
end

function set_target_for(player, target)
  local previous_target = get_target_for(player)
  if previous_target and previous_target.connected then
    get_base_element(player)[get_target_button_name(previous_target)].enabled = true
  end
  global.target[player.index] = target.index
  get_base_element(player)[get_target_button_name(target)].enabled = false
end

function get_target_button_name(player)
  return TARGET_BUTTONS_PREFIX .. player.name
end

-- Create the show toggle button
function create_show_toggle_button(player)
  return mod_gui.get_button_flow(player).add {
    type = "button",
    name = CAMERA_TOGGLE_BUTTON,
    caption = "Camera"
  }
end

-- Create the camera frame
function create_camera_frame(player)
  local root_element = player.gui.left

  -- Frame holding all mod ui elements
  local frame = mod_gui.get_frame_flow(player).add {
    type = "frame",
    name = "camera_frame",
    direction = "vertical"
  }
  local base_element = frame.add {
    type = "flow",
    name = "element_flow",
    direction = "vertical",
    style = "camerasan_container"
  }

  local camera_element = base_element.add {
    type = "camera",
    name="camera",
    position = player.position,
    surface_index = player.surface.index,
    zoom = 0.25,
    style = "camerasan_camera"
  }

  -- Add buttons for all connected players
  for _,other_player in pairs(game.players) do
    if other_player.connected then
      add_target_button(player, other_player)
    end
  end

  -- Set a default camera target
  set_target_for(player, player)

  return camera_element
end

-- Remove the camera frame for a given player
function destroy_camera_frame(player)
  local frame = get_frame(player)
  if frame then
    get_frame(player).destroy()
  end
end

function get_frame(player)
  return mod_gui.get_frame_flow(player).camera_frame
end

function get_base_element(player)
  return get_frame(player).element_flow
end

-- Add target button
function add_target_button(player, target)
  return get_base_element(player).add {
    type = "button",
    name = get_target_button_name(target),
    caption = target.name,
    style = "camerasan_target_button"
  }
end

-- Remove target button
function remove_target_button(player, target)
  local base_element = get_base_element(player)
  base_element[get_target_button_name(target)].destroy()
end

-- Update the camera position
function update_camera_element()
  for _,player in pairs(game.players) do
    if player.connected and global.show[player.index] then
      local camera_element = get_base_element(player).camera
      local target = get_target_for(player)
      camera_element.position = target.position
      camera_element.surface_index = target.surface.index
    end
  end
end


-- Utilities --


function has_value(table, value)
  for _,v in pairs(table) do
      if v == value then
          return true
      end
  end
  return false
end

function print_to(player, message)
  if DEBUG then
    player.print(serpent.block(message))
  end
end

-- vim: et:sw=2:ts=2
