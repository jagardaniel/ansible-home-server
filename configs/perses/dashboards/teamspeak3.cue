// An attempt at a Perses dashboard for a TeamSpeak 3 Server.
//
// Prometheus exporter used: https://github.com/wittdennis/ts3exporter (forked from hikhvar/ts3exporter)
// Layout idea from: https://grafana.com/grafana/dashboards/3020-teamspeak-3/

// The total percentage packet loss value can report lower than a more specific packetloss type (speech or control for example) which doesn't feel right. Not sure why.
// It also looks like ts3_serverinfo_bytes_received_total/ts3_serverinfo_bytes_send_total doesn't include the file transfer bytes. Maybe it is better to create
// our own total by adding all the specific types together.

package mydac

import (
	dashboardBuilder "github.com/perses/perses/cue/dac-utils/dashboard"
	labelValuesVarBuilder "github.com/perses/plugins/prometheus/sdk/cue/variable/labelvalues"
	panelBuilder "github.com/perses/plugins/prometheus/sdk/cue/panel"
	panelGroupsBuilder "github.com/perses/perses/cue/dac-utils/panelgroups"
	promQuery "github.com/perses/plugins/prometheus/schemas/prometheus-time-series-query:model"
	statChart "github.com/perses/plugins/statchart/schemas:model"
	timeseriesChart "github.com/perses/plugins/timeserieschart/schemas:model"
)

// The idea is to have some default settings and formatting that should apply to all panels. But I get some
// errors if I try to overwrite these values inside a panelBuilders spec, especially for colorMode on statcharts.
// So just use a separate planStatChart for now since I don't know how to solve it. ChatGPT couldn't help me!
// It could also be a good idea to move out this to another file or package so it can be shared between multiple dashboards.
#baseStatChart: statChart & {
	spec: {
		calculation:   "last-number"
		valueFontSize: 60
	}
}

#plainStatChart: #baseStatChart & {
	spec: {
		colorMode: "none"
	}
}

#baseTimeSeriesChart: timeseriesChart & {
	spec: {
		legend: {
			mode:     "table"
			position: "bottom"
			values: [
				"min",
				"max",
				"last",
				"mean",
			]
			"size": "small"
		}

		yAxis: {
			show: true
		}

		visual: {
			areaOpacity:  0.3
			connectNulls: false
			display:      "line"
			lineStyle:    "solid"
			lineWidth:    1.25
			pointRadius:  2.75
		}
	}
}

#clientsOnlineStatPanel: panelBuilder & {
	spec: {
		display: name: "Clients online"
		plugin: #plainStatChart

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: """
							ts3_serverinfo_clients_online{virtualserver="$virtualserver"}
							-
							ts3_serverinfo_query_clients_online{virtualserver="$virtualserver"}
							"""
					}
				}
			},
		]
	}
}

#maxClientsStatPanel: panelBuilder & {
	spec: {
		display: name: "Max clients"
		plugin: #plainStatChart

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: "ts3_serverinfo_max_clients{virtualserver=\"$virtualserver\"}"
					}
				}
			},
		]
	}
}

#channelsOnlineStatPanel: panelBuilder & {
	spec: {
		display: name: "Channels"
		plugin: #plainStatChart

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: "ts3_serverinfo_channels_online{virtualserver=\"$virtualserver\"}"
					}
				}
			},
		]
	}
}

#uptimeStatPanel: panelBuilder & {
	spec: {
		display: name: "Uptime"
		plugin: #plainStatChart & {
			spec: {
				format: {
					decimalPlaces: 2
					unit:          "seconds"
				}
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: "ts3_serverinfo_uptime{virtualserver=\"$virtualserver\"}"
					}
				}
			},
		]
	}
}

// This panel is probably a bit redundant since the dashboard variable only shows online servers.
#statusStatPanel: panelBuilder & {
	spec: {
		display: name: "Status"
		plugin: #baseStatChart & {
			spec: {
				mappings: [
					{
						kind: "Value"
						spec: {
							value: "0"
							result: {
								color: "#EA4747"
								value: "Offline"
							}
						}
					},
					{
						kind: "Value"
						spec: {
							value: "1"
							result: {
								color: "#2FBF71"
								value: "Online"
							}
						}
					},
				]
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: "ts3_serverinfo_online{virtualserver=\"$virtualserver\"}"
					}
				}
			},
		]
	}
}

#clientsOnlineTimePanel: panelBuilder & {
	spec: {
		display: name: "Clients online"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Clients"
					format: {
						unit:          "decimal"
						decimalPlaces: 0
					}
				}
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: """
							ts3_serverinfo_clients_online{virtualserver="$virtualserver"}
							-
							ts3_serverinfo_query_clients_online{virtualserver="$virtualserver"}
							"""
						seriesNameFormat: "Clients"
					}
				}
			},
		]
	}
}

#overallTrafficUsageTimePanel: panelBuilder & {
	spec: {
		display: name: "Overall traffic usage"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Bytes per second"
					format: unit: "bytes/sec"
				}

				querySettings: [
					{
						queryIndex: 1
						negativeY:  true
					}
				]
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_bytes_received_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Incoming traffic"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_bytes_send_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Outgoing traffic"
					}
				}
			},
		]
	}
}

#trafficUsageByTypeTimePanel: panelBuilder & {
	spec: {
		display: name: "Traffic usage by type"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Bytes per second"
					format: unit: "bytes/sec"
				}

				querySettings: [
					{
						queryIndex: 0
						negativeY:  true
					},
					{
						queryIndex: 2
						negativeY:  true
					},
					{
						queryIndex: 4
						negativeY:  true
					},
					{
						queryIndex: 6
						negativeY:  true
					},
				]
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_control_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Control - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_control_bytes_received_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Control - Received"
					}
				}
			},

			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_file_transfer_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "File transfer - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_file_transfer_bytes_received_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "File transfer - Received"
					}
				}
			},

			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_keepalive_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Keepalive - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_keepalive_bytes_received_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Keepalive - Received"
					}
				}
			},

			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_speech_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Speech - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_speech_bytes_received_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Speech - Received"
					}
				}
			},
		]
	}
}

#packetlossByTypeTimePanel: panelBuilder & {
	spec: {
		display: name: "Packet loss by type"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Packet loss"
					format: unit: "percent-decimal"
				}
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "ts3_serverinfo_total_packetloss_total{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Total"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "ts3_serverinfo_total_packetloss_speech{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Speech"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "ts3_serverinfo_total_packetloss_control{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Control"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "ts3_serverinfo_total_packetloss_keepalive{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Keepalive"
					}
				}
			},
		]
	}
}

#virtualServerVar: labelValuesVarBuilder & {
	#name:   "virtualserver"
	#metric: "ts3_serverinfo_online"
	#label:  "virtualserver"
}

dashboardBuilder & {
	#name:    "teamspeak_3"
	#project: "home"
	#display: name: "TeamSpeak 3"
	#duration:        "12h"
	#refreshInterval: "1m"
	#variables:       [#virtualServerVar.variable]

	#panelGroups: panelGroupsBuilder & {
		#input: [
			{
				#title:  "Overview"
				#cols:   6
				#height: 4
				#panels: [
					#clientsOnlineStatPanel,
					#maxClientsStatPanel,
					#channelsOnlineStatPanel,
					#uptimeStatPanel,
					#statusStatPanel,
				]
			},
			{
				#title:  "Performance"
				#cols:   2
				#height: 10
				#panels: [
					#clientsOnlineTimePanel,
					#overallTrafficUsageTimePanel,
					#trafficUsageByTypeTimePanel,
					#packetlossByTypeTimePanel,
				]
			},
		]
	}
}
