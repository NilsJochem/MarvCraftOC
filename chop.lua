local robot_api = require("robot")
local sides = require("sides")
local computer_api = require("computer")
local event = require("event")
local sleep_time = 5
local tool_slot = 15
local sapling_slot = 16

EVASION_STOP = 0
EVASION_WAIT_SHORT = 1
EVASION_WAIT_LONG = 2

local function move_raw(direction)
	if direction == sides.forward then
		return robot_api.forward()
	elseif direction == sides.down then
		return robot_api.down()
	elseif direction == sides.up then
		return robot_api.up()
	elseif direction == sides.back then
		return robot_api.back()
	end
end

local function move(direction, tiles, evasion_tactic, max_evasion_trys)
	max_evasion_trys = max_evasion_trys or 5
	tiles = tiles or 1
	if tiles <= 0 or max_evasion_trys <= 0 then
		return false
	end
	evasion_tactic = evasion_tactic or EVASION_STOP
	local moved, reason
	moved, reason = move_raw(direction)
	if not moved then
		print("couldn't move, gonna evade: "..reason)
		if evasion_tactic == EVASION_WAIT_SHORT then
			os.sleep(0.5)
			print("waited, trying to move again")
			move(direction, 1, evasion_tactic, max_evasion_trys-1)
		elseif evasion_tactic == EVASION_WAIT_LONG then
			os.sleep(5)
			print("waited, trying to move again")
			move(direction, 1, evasion_tactic, max_evasion_trys-1)
		else
			print("no retrying here")
			--default stop or unknown
			return true
		end
	end
	--successfully moved
	return move(direction, tiles-1, evasion_tactic, max_evasion_trys)
end

local function swing(up)
	local has_interacted, interaction
	if up then
		has_interacted, interaction = robot_api.swingUp()
	else
		has_interacted, interaction = robot_api.swing()
	end
  local dur, cur_dur, max_dur
	dur, cur_dur, max_dur = robot_api.durability()
  if not dur == nil then
		print("axe broke")
		local last_slot = robot_api.select()
		robot_api.select(tool_slot)
		robot_api.equip()
		robot_api.select(last_slot)
	end
	return has_interacted, interaction
end

local function wait_for_tree()
	local desc, interrupted
	repeat
		_, desc = robot_api.detect()
		io.write(".")
		interrupted = event.pull(sleep_time) == "interrupted"
	until desc == "solid" or interrupted

	print()
	if interrupted then
		print("interrupted programm")
		os.exit()
	else
		print("tree grown")
	end
end

local function chop_tree()
  swing(false)
	move(sides.forward, 1, EVASION_WAIT_SHORT)

  local _, desc = robot_api.detectUp()
	local br = true
	local blocks = 0
  while br and desc == "solid" do
		if not swing(true) then
			print("couldn't mine Block above")
			br = false
		else
			move(sides.up, 1, EVASION_WAIT_SHORT)
			_, desc = robot_api.detectUp()
			blocks = blocks + 1
		end
  end

	print("moving down")
	move(sides.down, blocks-1, EVASION_WAIT_SHORT)
	move(sides.down, 1, EVASION_STOP, 1)

	move(sides.back, 1, EVASION_WAIT_SHORT)
end

local function manage_inventory()
  local last_slot = robot_api.select()
  for i = 1, 16, 1 do
		if not(i == sapling_slot or i == tool_slot) then
			robot_api.select(i)
			robot_api.drop()
		end
  end
	local need_sapling, need_tool
	need_sapling = robot_api.count(sapling_slot)<=1
	need_tool = robot_api.count(tool_slot)<1

	--TODO provide tools
	need_tool = false

	if need_sapling or need_tool then
    move(sides.back, 2, EVASION_WAIT_LONG)
		if need_sapling then
			robot_api.select(sapling_slot)
			robot_api.suckDown(63)
		end
		if need_tool then
			--TODO get new tool
		end
    move(sides.forward, 2, EVASION_WAIT_LONG)
	end
  robot_api.select(last_slot)
	if false and computer_api.energy()/computer_api.maxEnergy() <= 0.15 then
		print("energy Level low")

    move(sides.back, 1, EVASION_WAIT_LONG)
		robot_api.turnLeft()
    move(sides.forward, 2, EVASION_WAIT_LONG)
    move(sides.down, 1, EVASION_WAIT_LONG)
		local interrupted
		repeat
			--just waiting
			interrupted = event.pull(5) == "interrupted"
		until computer_api.energy()/computer_api.maxEnergy() <= 0.95 or interrupted
		if interrupted then
			print("interrupted programm")
			os.exit()
		else
			print("filled up, back to work")
		end
    move(sides.up, 1, EVASION_WAIT_LONG)
    move(sides.back, 2, EVASION_WAIT_LONG)
		robot_api.turnRight()
    move(sides.forward, 1, EVASION_WAIT_LONG)
	end
end

local function plant_sapling()
  local last_slot = robot_api.select()
  robot_api.select(sapling_slot)
	if not robot_api.compare() then
		if not robot_api.place() then
			print("couldn't plant sapling")
			return false
		end
		print("planted new sapling")
	else
		print("sapling already planted")
	end
  robot_api.select(last_slot)
	return true
end

if false then
	move(sides.up, 2, EVASION_WAIT_SHORT)
	move(sides.down, 2, EVASION_WAIT_SHORT)
else
	repeat
		if not plant_sapling() then
			break
		end
		manage_inventory()

		io.write("waiting for new tree ")
		wait_for_tree()
		chop_tree()
	until event.pull(1) == "interrupted" -- # change 1 to something smaller to refresh faster
end

