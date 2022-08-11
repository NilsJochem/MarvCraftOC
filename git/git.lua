local shell = require("shell")


local config = {}
local f, err = loadfile("config.lua", "t", config)
if f then
	f()
else
	error(err)
end


local function get_path(file, repo)
	repo = repo or config.repo
	if not file then
		error("no filename for path providet")
	end
	return config.basepath..'/'..repo.."/main/"..file
end

local function load_file(url)
	shell.execute("wget "..url)
end

local args = {...}
load_file(get_path(args[1]))
