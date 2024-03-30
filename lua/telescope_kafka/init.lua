local plenary = require('plenary')
local log = require('plenary.log').new {
  plugin = 'telescope_kafka',
  level = 'info',
}
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')

---@class Topic
---@field topic string

---@class TKModule
---@field config TKConfig
---@field setup fun(TKConfig): TKModule

---@class TKConfig
---@field kcat_path string | nil

local M = {}

---@param args string[]
local kcat = function(args)
  table.insert(args, '-J')
  local job_opts = {
    command = M.config.kcat_path or 'kcat',
    args = args,
  }
  log.info('Running job', job_opts)
  local job = plenary.job:new(job_opts):sync()
  return vim.json.decode(job[1])
end

M.kafka_topics = function(opts)
  pickers
    .new(opts, {
      prompt_title = 'Kafka Topics',
      finder = finders.new_dynamic({
        fn = function()
          ---@type {topics:Topic[]} | nil
          local fields = kcat({ '-L' })

          local result = {}

          -- Hide internal topics.
          if fields then
            for _, entry in pairs(fields.topics) do
              if not vim.startswith(entry.topic, '_') then
                table.insert(result, entry)
              end
            end
          end

          return result
        end,

        entry_maker = function(entry)
          log.debug('Calling entry maker', vim.inspect(entry))
          return {
            value = entry,
            display = entry.topic,
            ordinal = entry.topic,
          }
        end,
      }),

      sorter = conf.generic_sorter(opts),

      previewer = previewers.new_buffer_previewer({
        title = 'Details',
        define_preview = function(self, entry)
          local formatted = {
            '# ' .. entry.value.topic,
            '',
            string.format('Partition count: %d', #entry.value.partitions),
            '',
          }
          for _, partition in ipairs(entry.value.partitions) do
            table.insert(
              formatted,
              string.format('Partition %3d Leader %3d', partition.partition, partition.leader)
            )
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)

          utils.highlighter(self.state.bufnr, 'markdown')
        end,
      }),

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end

---@param config TKConfig
function M.setup(config)
  M.config = config
end

-- vim.keymap.set('n', '<Leader>w', function()
--   vim.api.nvim_command(':write')
--
--   vim.cmd('source %')
-- end)
--
-- M.kafka_topics()

return M
