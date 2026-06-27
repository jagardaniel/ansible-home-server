package mydac

import (
	dashboardBuilder "github.com/perses/perses/cue/dac-utils/dashboard"
	panelGroupsBuilder "github.com/perses/perses/cue/dac-utils/panelgroups"
	varGroupBuilder "github.com/perses/perses/cue/dac-utils/variable/group"
	labelValuesVarBuilder "github.com/perses/plugins/prometheus/sdk/cue/variable/labelvalues"
	panelBuilder "github.com/perses/plugins/prometheus/sdk/cue/panel"
	promQuery "github.com/perses/plugins/prometheus/schemas/prometheus-time-series-query:model"
	statChart "github.com/perses/plugins/statchart/schemas:model"
	timeseriesChart "github.com/perses/plugins/timeserieschart/schemas:model"
)

// A first attempt at a Perses dashboard for a TeamSpeak 3 server.
// Prometheus exporter used: https://github.com/wittdennis/ts3exporter (forked from hikhvar/ts3exporter)
// Layout idea from https://grafana.com/grafana/dashboards/3020-teamspeak-3/

// I haven't been able to figure out how to set the width of specific panels. So right now the statchart panels are in their own panel group to keep them small.
// TimeSeriesCharts does not have the option for a negative Y (https://github.com/perses/perses/issues/3315) so a "workaround" is to place a "-" in front of the query
// to make it negative. It will show up as a negative value in the graph and the tables though.

// The total percentage packet loss value can also report lower than a more specific packetloss type (speech or control for example) which doesn't feel right. Not sure why.
// It also looks like ts3_serverinfo_bytes_received_total/ts3_serverinfo_bytes_send_total doesn't include the file transfer bytes. Maybe it is better to create
// our own total by adding all the specific types together.

// Default styling for all statcharts
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

// Default styling for all timeseriescharts
#baseTimeSeriesChart: timeseriesChart & {
	spec: {
		legend: {
			mode:     "table"
			position: "bottom"
			values: [
				"min",
				"max",
				"last",
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
						query: "ts3_serverinfo_clients_online{virtualserver=\"$virtualserver\"} - ts3_serverinfo_query_clients_online{virtualserver=\"$virtualserver\"}"
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
		display: name: "Channels online"
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

// This will probably always display online because the dashboard variable only lists online virtual servers.
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
						query:            "ts3_serverinfo_clients_online{virtualserver=\"$virtualserver\"} - ts3_serverinfo_query_clients_online{virtualserver=\"$virtualserver\"}"
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
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(ts3_serverinfo_bytes_received_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Total - Received"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "-rate(ts3_serverinfo_bytes_send_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Total - Sent"
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
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "-rate(ts3_serverinfo_control_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
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
						query:            "-rate(ts3_serverinfo_file_transfer_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
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
						query:            "-rate(ts3_serverinfo_keepalive_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
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
						query:            "-rate(ts3_serverinfo_speech_bytes_sent_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
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

#varsBuilder: varGroupBuilder & {
	#input: [
		labelValuesVarBuilder & {
			#name:   "virtualserver"
			#metric: "ts3_serverinfo_online"
			#label:  "virtualserver"
		},
	]
}

dashboardBuilder & {
	#name:    "teamspeak_3"
	#project: "home"
	#display: name: "TeamSpeak 3"
	#duration:        "12h"
	#refreshInterval: "1m"
	#variables:       #varsBuilder.variables

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
