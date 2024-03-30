---@diagnostic disable: undefined-field
local expect = MiniTest.expect
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      child.lua [[ vim.cmd('set rtp+=deps/plenary.nvim') ]]
      child.lua [[ vim.cmd('set rtp+=deps/telescope.nvim') ]]
      child.lua [[ M = require('telescope_kafka') ]]

      child.bo.readonly = false
      child.lua [[ vim.o.lines = 50 ]]
      child.lua [[ vim.o.columns = 160 ]]
    end,
    post_once = child.stop,
  },
})

T.kafka_topics = function()
  child.lua [[M.kafka_topics()]]
  expect.reference_screenshot(child.get_screenshot())
end

return T
