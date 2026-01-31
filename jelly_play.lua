local function play_markdown_id()
	-- Check if the current buffer is a markdown file
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	-- Read the entire buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

	-- Parse frontmatter
	for _, line in ipairs(lines) do
		if line:match("^---") then
			if not in_frontmatter then
				in_frontmatter = true
			else
				break
			end
		elseif in_frontmatter then
			local key, value = line:match("^(%w+):%s*(.+)$")
			if key and value then
				frontmatter[key] = value:gsub('^"', ""):gsub('"$', "")
			end
		end
	end

	-- Check if 'id' exists in frontmatter
	if not frontmatter.id then
		print("No 'id' found in frontmatter")
		return
	end

	-- Async job to run the command
	vim.fn.jobstart({ "/home/ylan/.local/bin/jelly_play_yt", frontmatter.locator }, {
		on_exit = function(_, code)
			if code == 0 then
				-- print("Successfully played: " .. frontmatter.id)
			else
				print("Error playing: " .. frontmatter.id)
			end
		end,
	})
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.keymap.set("n", "<leader>bp", play_markdown_id, { buffer = true })
	end,
})
