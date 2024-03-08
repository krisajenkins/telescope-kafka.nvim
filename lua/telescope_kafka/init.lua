local plenary = require('plenary')
local log = require('telescope.log')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local previewers = require('telescope.previewers')

local M = {}

local kcat = function(args)
  table.insert(args, '-J')
  local job_opts = {
    command = M.config.kcat_path,
    args = args,
  }
  log.debug('Runninng dynamic job', job_opts)
  local job = plenary.job:new(job_opts):sync()
  return vim.json.decode(job[1])
end

M.kafka_topics = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = 'Topics',
      finder = finders.new_dynamic({
        fn = function()
          log.debug('Running dynamic job')
          local fields = kcat({ '-L' })

          local result = {}

          -- Hide internal topics.
          for _, entry in pairs(fields.topics) do
            if not vim.startswith(entry.topic, '_') then
              table.insert(result, entry)
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
        define_preview = function(self, entry, _status)
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
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, formatted)

          require('telescope.previewers.utils').highlighter(
            self.state.bufnr,
            'markdown',
            { preview = { treesitter = { enable = {} } } }
          )
        end,
      }),

      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end

M.setup = function(config, _is_auto_config)
  M.config = config
end

return M
