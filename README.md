# Telescope Kafka

A prototype/sketch/WIP cluster explorer for Kafka.

## Status

100% hacked-together. Enter at your own risk. 😁

## Installation & Configuration

You need `kcat` installed. You also need to make sure you've configured
`~/.config/kcat.conf` so that `kcat -L` connects to the right cluster. (See [this
blogpost](http://blog.jenkster.com/2022/10/setting-up-kcat-config.html) for
help.)

Lazy: 

```lua
{
	"krisajenkins/telescope-kafka.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("telescope").load_extension("telescope_kafka")
		require("telescope_kafka").setup({
			kcat_path = "<path to kcat>",
		})
		vim.keymap.set(
			"n",
			"<Leader>kt",
			":Telescope telescope_kafka kafka_topics<CR>",
			{ desc = "[K]afka [T]opics" }
		)
	end,
}
```
