// An attempt to copy most panels/queries from Node Exporter Full dashboard:
// https://grafana.com/grafana/dashboards/1860-node-exporter-full/
// https://github.com/rfmoz/grafana-dashboards.git
//
// Promethes exporter used: Official node_exporter - https://github.com/prometheus/node_exporter

package mydac

import (
	dashboardBuilder "github.com/perses/perses/cue/dac-utils/dashboard"
	labelValuesVarBuilder "github.com/perses/plugins/prometheus/sdk/cue/variable/labelvalues"
	panelBuilder "github.com/perses/plugins/prometheus/sdk/cue/panel"
	panelGroupsBuilder "github.com/perses/perses/cue/dac-utils/panelgroups"
	promQuery "github.com/perses/plugins/prometheus/schemas/prometheus-time-series-query:model"
	timeseriesChart "github.com/perses/plugins/timeserieschart/schemas:model"
	gaugeChart "github.com/perses/plugins/gaugechart/schemas:model"
	statChart "github.com/perses/plugins/statchart/schemas:model"
)

#baseTimeSeriesChart: timeseriesChart & {
	spec: {
		visual: {
			areaOpacity: 0.4
			display:     "line"
			lineStyle:   "solid"
			lineWidth:   1.25
			pointRadius: 2.75
		}

		legend: position: "bottom"
	}
}

#detailedTimeSeriesChart: #baseTimeSeriesChart & {
	spec: {
		legend: {
			mode:     "table"
			position: "bottom"
			values: [
				"min",
				"max",
				"mean",
			]
			"size": "small"
		}

		yAxis: {
			show: true
		}
	}
}

#baseGaugeChart: gaugeChart & {
	spec: {
		format: {
			unit:          "percent"
			decimalPlaces: 1
		}
		legend: show: false
	}
}

#baseStatChart: statChart & {
	spec: {
		colorMode: "none"
	}
}

#CPUBusyGaugePanel: panelBuilder & {
	spec: {
		display: {
			name:        "CPU Busy"
			description: "Overall CPU busy percentage (averaged across all cores)"
		}
		plugin: #baseGaugeChart & {
			spec: {
				thresholds: {
					steps: [
						{"value": 85, "color": "#FF9F1C"},
						{"value": 95, "color": "#EA4747"},
					]
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle",instance="$instance",job="$job"}[$__rate_interval])))"#
					}
				}
			},
		]
	}
}

#sysLoadGaugePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Sys Load"
			description: "System load over all CPU cores together"
		}
		plugin: #baseGaugeChart & {
			spec: {
				thresholds: {
					steps: [
						{"value": 85, "color": "#FF9F1C"},
						{"value": 95, "color": "#EA4747"},
					]
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"scalar(node_load1{instance="$instance",job="$job"}) * 100 / count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu))"#
					}
				}
			},
		]
	}
}

#RAMUsedGaugePanel: panelBuilder & {
	spec: {
		display: {
			name:        "RAM Used"
			description: "Real RAM usage excluding cache and reclaimable memory"
		}
		plugin: #baseGaugeChart & {
			spec: {
				thresholds: {
					steps: [
						{"value": 80, "color": "#FF9F1C"},
						{"value": 90, "color": "#EA4747"},
					]
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"clamp_min((1 - (node_memory_MemAvailable_bytes{instance="$instance", job="$job"} / node_memory_MemTotal_bytes{instance="$instance", job="$job"})) * 100, 0)"#
					}
				}
			},
		]
	}
}

#SWAPUsedGaugePanel: panelBuilder & {
	spec: {
		display: {
			name:        "SWAP Used"
			description: "Percentage of swap space currently used by the system"
		}
		plugin: #baseGaugeChart & {
			spec: {
				thresholds: {
					steps: [
						{"value": 10, "color": "#FF9F1C"},
						{"value": 25, "color": "#EA4747"},
					]
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"(node_memory_SwapTotal_bytes{instance="$instance",job="$job"} > bool 0) * ((node_memory_SwapTotal_bytes{instance="$instance",job="$job"} - node_memory_SwapFree_bytes{instance="$instance",job="$job"}) / (node_memory_SwapTotal_bytes{instance="$instance",job="$job"})) * 100"#
					}
				}
			},
		]
	}
}

#rootFSUsedGaugePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Root FS Used"
			description: "Used Root FS"
		}
		plugin: #baseGaugeChart & {
			spec: {
				thresholds: {
					steps: [
						{"value": 80, "color": "#FF9F1C"},
						{"value": 90, "color": "#EA4747"},
					]
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"((node_filesystem_size_bytes{instance="$instance", job="$job", mountpoint="/", fstype!="rootfs"} - node_filesystem_avail_bytes{instance="$instance", job="$job", mountpoint="/", fstype!="rootfs"}) / node_filesystem_size_bytes{instance="$instance", job="$job", mountpoint="/", fstype!="rootfs"}) * 100"#
					}
				}
			},
		]
	}
}

#CPUCoresStatPanel: panelBuilder & {
	spec: {
		display: {
			name: "CPU Cores"
		}
		plugin: #baseStatChart & {
			spec: {}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu))"#
					}
				}
			},
		]
	}
}

#RAMTotalStatPanel: panelBuilder & {
	spec: {
		display: {
			name: "RAM Total"
		}
		plugin: #baseStatChart & {
			spec: {
				format: {
					unit: "bytes"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"node_memory_MemTotal_bytes{instance="$instance",job="$job"}"#
					}
				}
			},
		]
	}
}

#SWAPTotalStatPanel: panelBuilder & {
	spec: {
		display: {
			name: "SWAP Total"
		}
		plugin: #baseStatChart & {
			spec: {
				format: {
					unit: "bytes"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"node_memory_SwapTotal_bytes{instance="$instance",job="$job"}"#
					}
				}
			},
		]
	}
}

#rootFSTotalStatPanel: panelBuilder & {
	spec: {
		display: {
			name: "RootFS Total"
		}
		plugin: #baseStatChart & {
			spec: {
				format: {
					unit: "bytes"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"node_filesystem_size_bytes{instance="$instance",job="$job",mountpoint="/",fstype!="rootfs"}"#
					}
				}
			},
		]
	}
}

#uptimeStatPanel: panelBuilder & {
	spec: {
		display: {
			name: "Uptime"
		}
		plugin: #baseStatChart & {
			spec: {
				format: {
					unit: "seconds"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"node_time_seconds{instance="$instance",job="$job"} - node_boot_time_seconds{instance="$instance",job="$job"}"#
					}
				}
			},
		]
	}
}

#CPUBasicTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "CPU Basic"
			description: "CPU time spent busy vs idle, split by activity type"
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "percent-decimal"
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(rate(node_cpu_seconds_total{instance="$instance",job="$job", mode="system"}[$__rate_interval]))"#
						seriesNameFormat: "Busy System"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(rate(node_cpu_seconds_total{instance="$instance",job="$job", mode="user"}[$__rate_interval]))"#
						seriesNameFormat: "Busy User"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(rate(node_cpu_seconds_total{instance="$instance",job="$job", mode="iowait"}[$__rate_interval]))"#
						seriesNameFormat: "Busy Iowait"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(sum without(mode) (rate(node_cpu_seconds_total{instance="$instance",job="$job", mode=~".*irq"}[$__rate_interval])))"#
						seriesNameFormat: "Busy IRQs"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(sum without (mode) (rate(node_cpu_seconds_total{instance="$instance",job="$job",  mode!='idle',mode!='user',mode!='system',mode!='iowait',mode!='irq',mode!='softirq'}[$__rate_interval])))"#
						seriesNameFormat: "Busy Other"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(rate(node_cpu_seconds_total{instance="$instance",job="$job", mode="idle"}[$__rate_interval]))"#
						seriesNameFormat: "Idle"
					}
				}
			},
		]
	}
}

#memoryBasicTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Basic"
			description: "RAM and swap usage overview, including caches"
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "bytes"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_MemTotal_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Total"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_MemTotal_bytes{instance="$instance",job="$job"} - node_memory_MemFree_bytes{instance="$instance",job="$job"} - (node_memory_Cached_bytes{instance="$instance",job="$job"} + node_memory_Buffers_bytes{instance="$instance",job="$job"} + node_memory_SReclaimable_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "Used"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Cached_bytes{instance="$instance",job="$job"} + node_memory_Buffers_bytes{instance="$instance",job="$job"} + node_memory_SReclaimable_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Cache + Buffer"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_MemFree_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Free"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_memory_SwapTotal_bytes{instance="$instance",job="$job"} - node_memory_SwapFree_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "SWAP used"
					}
				}
			},
		]
	}
}

#networkTrafficBasicTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Network Traffic Basic"
			description: "Per-interface network traffic (receive and transmit) in bits per second"
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "decbits/sec"
				querySettings: [
					{queryIndex: 1, negativeY: true}, // Transmit
				]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_network_receive_bytes_total{instance="$instance",job="$job"}[$__rate_interval])*8"#
						seriesNameFormat: "Rx {{device}}"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_network_transmit_bytes_total{instance="$instance",job="$job"}[$__rate_interval])*8"#
						seriesNameFormat: "Tx {{device}}"
					}
				}
			},
		]
	}
}

#diskSpaceUsedBasicTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Space Used Basic"
			description: "Percentage of filesystem space used for each mounted device"
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "percent"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"((node_filesystem_size_bytes{instance="$instance", job="$job", device!~'rootfs'} - node_filesystem_avail_bytes{instance="$instance", job="$job", device!~'rootfs'}) / node_filesystem_size_bytes{instance="$instance", job="$job", device!~'rootfs'}) * 100"#
						seriesNameFormat: "{{mountpoint}}"
					}
				}
			},
		]
	}
}

// Guest CPU usage query not included from the Grafana panel
#CPUTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "CPU"
			description: "CPU time usage split by state, normalized across all CPU cores"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "percent-decimal"
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="system",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "System - Processes executing in kernel mode"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="user",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "User - Normal processes executing in user mode"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="nice",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "Nice - Niced processes executing in user mode"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="iowait",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "Iowait - Waiting for I/O to complete"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="irq",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "Irq - Servicing interrupts"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="softirq",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "Softirq - Servicing softirqs"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="steal",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "Steal - Time spent in other operating systems when running in a virtualized environment"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(rate(node_cpu_seconds_total{mode="idle",instance="$instance",job="$job"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu)))"#
						seriesNameFormat: "Idle - Waiting for something to happen"
					}
				}
			},
		]
	}
}

#memoryTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory"
			description: "Breakdown of physical memory and swap usage. Hardware-detected memory errors are also displayed"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "bytes"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_MemTotal_bytes{instance="$instance",job="$job"} - node_memory_MemFree_bytes{instance="$instance",job="$job"} - node_memory_Buffers_bytes{instance="$instance",job="$job"} - node_memory_Cached_bytes{instance="$instance",job="$job"} - node_memory_Slab_bytes{instance="$instance",job="$job"} - node_memory_PageTables_bytes{instance="$instance",job="$job"} - node_memory_SwapCached_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Apps - Memory used by user-space applications"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_PageTables_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "PageTables - Memory used to map between virtual and physical memory addresses"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_SwapCached_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "SwapCache - Memory that keeps track of pages that have been fetched from swap but not yet been modified"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Slab_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Slab - Memory used by the kernel to cache data structures for its own use (caches like inode, dentry, etc)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Cached_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Cache - Parked file data (file content) cache"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Buffers_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Buffers - Block device (e.g. harddisk) cache"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_MemFree_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Unused - Free memory unassigned"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_memory_SwapTotal_bytes{instance="$instance",job="$job"} - node_memory_SwapFree_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "Swap - Swap space used"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_HardwareCorrupted_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Hardware Corrupted - Amount of RAM that the kernel identified as corrupted / not working"
					}
				}
			},
		]
	}
}

#networkTrafficTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Network Traffic"
			description: "Incoming and outgoing network traffic per interface"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decbits/sec"
					show:  true
					label: "out (-) / in (+)"
				}
				querySettings: [
					{queryIndex: 1, negativeY: true}, // Transmit
				]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_network_receive_bytes_total{instance="$instance",job="$job"}[$__rate_interval])*8"#
						seriesNameFormat: "{{device}} - Rx in"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_network_transmit_bytes_total{instance="$instance",job="$job"}[$__rate_interval])*8"#
						seriesNameFormat: "{{device}} - Tx out"
					}
				}
			},
		]
	}
}

#networkSaturationTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Network Saturation"
			description: "Network interface utilization as a percentage of its maximum capacity"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent-decimal"
					show:  true
					label: "out (-) / in (+)"
				}
				querySettings: [
					{queryIndex: 1, negativeY: true}, // Transmit
				]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_network_speed_bytes{instance="$instance",job="$job"} > bool 0) * (rate(node_network_receive_bytes_total{instance="$instance",job="$job"}[$__rate_interval]) / node_network_speed_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "{{device}} - Rx in"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_network_speed_bytes{instance="$instance",job="$job"} > bool 0) * (rate(node_network_transmit_bytes_total{instance="$instance",job="$job"}[$__rate_interval]) / node_network_speed_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "{{device}} - Tx out"
					}
				}
			},
		]
	}
}

#jobVar: labelValuesVarBuilder & {
	#name:  "job"
	#label: "job"
	#query: "node_uname_info"
}

#instanceVar: labelValuesVarBuilder & {
	#name:  "instance"
	#label: "instance"
	#query: #"node_uname_info{job="$job"}"#
}

dashboardBuilder & {
	#name:    "node_exporter"
	#project: "home"
	#display: name: "Node Exporter"
	#duration:        "12h"
	#refreshInterval: "1m"
	#variables:       [#jobVar.variable, #instanceVar.variable]

	#panelGroups: panelGroupsBuilder & {
		#input: [
			{
				#title:  "Quick CPU / Mem / Disk"
				#cols:   10
				#height: 4
				#panels: [
					#CPUBusyGaugePanel,
					#sysLoadGaugePanel,
					#RAMUsedGaugePanel,
					#SWAPUsedGaugePanel,
					#rootFSUsedGaugePanel,
					#CPUCoresStatPanel,
					#RAMTotalStatPanel,
					#SWAPTotalStatPanel,
					#rootFSTotalStatPanel,
					#uptimeStatPanel,
				]
			},
			{
				#title:  "Basic CPU / Mem / Net / Disk"
				#cols:   2
				#height: 8
				#panels: [
					#CPUBasicTimePanel,
					#memoryBasicTimePanel,
					#networkTrafficBasicTimePanel,
					#diskSpaceUsedBasicTimePanel,
				]
			},
			{
				#title:       "CPU / Mem / Net / Disk"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#CPUTimePanel,
					#memoryTimePanel,
					#networkTrafficTimePanel,
					#networkSaturationTimePanel,
				]
			},
		]
	}
}
