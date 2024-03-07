local telescope_kafka = require("telescope_kafka")

return require("telescope").register_extension({
	exports = {
		kafka_topics = telescope_kafka.kafka_topics,
	},
})
