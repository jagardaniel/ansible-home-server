// An attempt at a Perses dashboard for a TeamSpeak 3 Server.
//
// Prometheus exporter used: https://github.com/jagardaniel/teamspeak_exporter
// Layout idea from: https://grafana.com/grafana/dashboards/3020-teamspeak-3/

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
// So just use a separate planStatChart for now since I don't know how to solve it.
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

// Clients online also includes query clients so we have to subtract query_clients to get the count of regular voice clients.
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
							teamspeak_virtualserver_clients_online{virtualserver="$virtualserver"}
							-
							teamspeak_virtualserver_query_clients_online{virtualserver="$virtualserver"}
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
						query: "teamspeak_virtualserver_max_clients{virtualserver=\"$virtualserver\"}"
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
						query: "teamspeak_virtualserver_channels_online{virtualserver=\"$virtualserver\"}"
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
						query: "teamspeak_virtualserver_uptime_seconds{virtualserver=\"$virtualserver\"}"
					}
				}
			},
		]
	}
}

#versionStatPanel: panelBuilder & {
	spec: {
		display: name: "Version"
		plugin: #plainStatChart & {
			spec: {
				metricLabel: "version"
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: "teamspeak_version_info"
					}
				}
			},
		]
	}
}

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
					{
						kind: "Value"
						spec: {
							value: "2"
							result: {
								color: "#FFCC00"
								value: "Virtual online"
							}
						}
					},
					{
						kind: "Value"
						spec: {
							value: "3"
							result: {
								color: "#FF9F1C"
								value: "Booting up"
							}
						}
					},
					{
						kind: "Value"
						spec: {
							value: "4"
							result: {
								color: "#FF9F1C"
								value: "Shutting down"
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
						query: "teamspeak_virtualserver_status{virtualserver=\"$virtualserver\"}"
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
						unit: "decimal"
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
							teamspeak_virtualserver_clients_online{virtualserver="$virtualserver"}
							-
							teamspeak_virtualserver_query_clients_online{virtualserver="$virtualserver"}
							"""
						seriesNameFormat: "Clients"
					}
				}
			},
		]
	}
}

// Bytes for file transfer is not included in the total sent/received bytes. Add them to the total.
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
						query:            "rate(teamspeak_virtualserver_received_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval]) + rate(teamspeak_virtualserver_received_file_transfer_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Traffic - Received"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval]) + rate(teamspeak_virtualserver_sent_file_transfer_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Traffic - Sent"
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
					{queryIndex: 0, negativeY: true},
					{queryIndex: 2, negativeY: true},
					{queryIndex: 4, negativeY: true},
					{queryIndex: 6, negativeY: true},
				]
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_control_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Control - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_control_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Control - Received"
					}
				}
			},

			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_file_transfer_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "File transfer - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_file_transfer_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "File transfer - Received"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_keepalive_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Keepalive - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_keepalive_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Keepalive - Received"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_speech_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Speech - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_speech_bytes_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
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
						query:            "teamspeak_virtualserver_packetloss_total_percent{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Total"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "teamspeak_virtualserver_packetloss_speech_percent{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Speech"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "teamspeak_virtualserver_packetloss_control_percent{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Control"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "teamspeak_virtualserver_packetloss_keepalive_percent{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Packet loss - Keepalive"
					}
				}
			},
		]
	}
}

#PingTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Average client ping"
			description: "The average ping of all clients connected to the virtual server."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Ping"
					format: {
						unit: "seconds"
					}
				}
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "teamspeak_virtualserver_ping_seconds{virtualserver=\"$virtualserver\"}"
						seriesNameFormat: "Ping - Average"
					}
				}
			},
		]
	}
}

#packetsByTypeTimePanel: panelBuilder & {
	spec: {
		display: name: "Packets by type"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Packets per second"
					format: unit: "packets/sec"
				}

				querySettings: [
					{queryIndex: 0, negativeY: true},
					{queryIndex: 2, negativeY: true},
					{queryIndex: 4, negativeY: true},
				]
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_control_packets_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Control - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_control_packets_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Control - Received"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_keepalive_packets_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Keepalive - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_keepalive_packets_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Keepalive - Received"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_sent_speech_packets_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Speech - Sent"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_received_speech_packets_total{virtualserver=\"$virtualserver\"}[$__rate_interval])"
						seriesNameFormat: "Speech - Received"
					}
				}
			},
		]
	}
}

// I'm not sure how to display these two values in the best way. Maybe if you could get the exact numbers of connections between two scrapes and just show
// that as a number but I can't figure that out.
#clientConnectionsTimePanel: panelBuilder & {
	spec: {
		display: {
			name: "Client connections (rate)"
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					label: "Connections / min"
					format: unit: "decimal"
				}
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_client_connections_total{virtualserver=\"$virtualserver\"}[$__rate_interval]) * 60"
						seriesNameFormat: "Connections - Regular"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            "rate(teamspeak_virtualserver_query_client_connections_total{virtualserver=\"$virtualserver\"}[$__rate_interval]) * 60"
						seriesNameFormat: "Connections - Query"
					}
				}
			},
		]
	}
}

#virtualServerVar: labelValuesVarBuilder & {
	#name:   "virtualserver"
	#metric: "teamspeak_virtualserver_up"
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
					#versionStatPanel,
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
					#PingTimePanel,
					#packetsByTypeTimePanel,
					#clientConnectionsTimePanel,
				]
			},
		]
	}
}
