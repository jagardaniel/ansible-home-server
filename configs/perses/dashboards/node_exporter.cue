// An attempt to copy most panels/queries from Node Exporter Full dashboard.
// So layout, queries and panels are made by the person or people behind the Grafana Node Exporter Full dashboard:
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
				querySettings: [{queryIndex: 1, negativeY: true}] // Transmit
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
				querySettings: [{queryIndex: 1, negativeY: true}] // Transmit
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
				querySettings: [{queryIndex: 1, negativeY: true}] // Transmit
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

#diskIOpsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk IOps"
			description: "Disk I/O operations per second for each device"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
					show:  true
					label: "read (-) / write (+)"
				}
				querySettings: [{queryIndex: 0, negativeY: true}] // Read
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_reads_completed_total{instance="$instance",job="$job",device=~"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+"}[$__rate_interval])"#
						seriesNameFormat: "{{device}} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_writes_completed_total{instance="$instance",job="$job",device=~"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+"}[$__rate_interval])"#
						seriesNameFormat: "{{device}} - Write"
					}
				}
			},
		]
	}
}

#diskThroughputTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Throughput"
			description: "Disk I/O throughput per device"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decbytes/sec"
					show:  true
					label: "read (-) / write (+)"
				}
				querySettings: [{queryIndex: 0, negativeY: true}] // Read
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_read_bytes_total{instance="$instance",job="$job",device=~"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+"}[$__rate_interval])"#
						seriesNameFormat: "{{device}} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_written_bytes_total{instance="$instance",job="$job",device=~"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+"}[$__rate_interval])"#
						seriesNameFormat: "{{device}} - Write"
					}
				}
			},
		]
	}
}

#filesystemSpaceTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Filesystem Space Available"
			description: "Amount of available disk space per mounted filesystem, excluding rootfs. Based on block availability to non-root users"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_filesystem_avail_bytes{instance="$instance",job="$job",device!~'rootfs'}"#
						seriesNameFormat: "{{mountpoint}}"
					}
				}
			},
		]
	}
}

#filesystemUsedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Filesystem Used"
			description: "Disk usage (used = total - available) per mountpoint"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_filesystem_size_bytes{instance="$instance",job="$job",device!~'rootfs'} - node_filesystem_avail_bytes{instance="$instance",job="$job",device!~'rootfs'}"#
						seriesNameFormat: "{{mountpoint}}"
					}
				}
			},
		]
	}
}

#diskIOUtilizationTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk I/O Utilization"
			description: "Percentage of time the disk was actively processing I/O operations"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent-decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_io_time_seconds_total{instance="$instance",job="$job",device=~"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+"} [$__rate_interval])"#
						seriesNameFormat: "{{device}}"
					}
				}
			},
		]
	}
}

#pressureStallInfoTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Pressure Stall Information"
			description: "How often tasks experience CPU, memory, or I/O delays. 'Some' indicates partial slowdown; 'Full' indicates all tasks are stalled. Based on Linux PSI metrics: https://docs.kernel.org/accounting/psi.html"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent-decimal"
					show:  true
					label: "some (-) / full (+)"
				}
				querySettings: [
					{queryIndex: 0, negativeY: true}, // CPU - Some
					{queryIndex: 1, negativeY: true}, // Memory - Some
					{queryIndex: 3, negativeY: true}, // I/O - Some
				]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_pressure_cpu_waiting_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "CPU - Some"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_pressure_memory_waiting_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Memory - Some"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_pressure_memory_stalled_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Memory - Full"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_pressure_io_waiting_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "I/O - Some"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_pressure_io_stalled_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "I/O - Full"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_pressure_irq_stalled_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "IRQ - Full"
					}
				}
			},
		]
	}
}

#memoryCommitedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Committed"
			description: "Displays committed memory usage versus the system's commit limit. Exceeding the limit is allowed under Linux overcommit policies but may increase OOM risks under high load"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "bytes"
				}
				querySettings: [
					{queryIndex: 0, colorMode: "fixed", colorValue: "#2FBF71"},
					{queryIndex: 1, areaOpacity: 0, colorMode: "fixed", colorValue: "#EA4747"},
				]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Committed_AS_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Committed_AS - Memory promised to processes (not necessarily used)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_CommitLimit_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "CommitLimit - Max allowable committed memory"
					}
				}
			},
		]
	}
}

#memoryWritebackDirtyTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Writeback and Dirty"
			description: "Memory currently dirty (modified but not yet written to disk), being actively written back, or held by writeback buffers. High dirty or writeback memory may indicate disk I/O pressure or delayed flushing"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_Writeback_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Writeback - Memory currently being flushed to disk"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_WritebackTmp_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "WritebackTmp - FUSE temporary writeback buffers"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Dirty_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Dirty - Memory marked dirty (pending write to disk)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_NFS_Unstable_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "NFS Unstable - Pages sent to NFS server, awaiting storage commit"
					}
				}
			},
		]
	}
}

#memorySlabTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Slab"
			description: "Kernel slab memory usage, separated into reclaimable and non-reclaimable categories. Reclaimable memory can be freed under memory pressure (e.g., caches), while unreclaimable memory is locked by the kernel for core functions"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_SUnreclaim_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "SUnreclaim - Non-reclaimable slab memory (kernel objects)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_SReclaimable_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "SReclaimable - Potentially reclaimable slab memory (e.g., inode cache)"
					}
				}
			},
		]
	}
}

#memorySharedMappedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Shared and Mapped"
			description: "Memory used for mapped files (such as libraries) and shared memory (shmem and tmpfs), including variants backed by huge pages"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_Mapped_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Mapped - Memory mapped from files (e.g., libraries, mmap)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Shmem_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Shmem - Shared memory used by processes and tmpfs"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_ShmemHugePages_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "ShmemHugePages - Shared memory (shmem/tmpfs) allocated with HugePages"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_ShmemPmdMapped_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "PMD Mapped - Shmem/tmpfs backed by Transparent HugePages (PMD)"
					}
				}
			},
		]
	}
}

#memoryLRUTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory LRU Active / Inactive (%)"
			description: "Proportion of memory pages in the kernel's active and inactive LRU lists relative to total RAM. Active pages have been recently used, while inactive pages are less recently accessed but still resident in memory"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent-decimal"
				}
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_memory_Inactive_bytes{instance="$instance",job="$job"})/(node_memory_MemTotal_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "Inactive - Less recently used memory, more likely to be reclaimed"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_memory_Active_bytes{instance="$instance",job="$job"})/(node_memory_MemTotal_bytes{instance="$instance",job="$job"})"#
						seriesNameFormat: "Active - Recently used memory, retained unless under pressure"
					}
				}
			},
		]
	}
}

#memoryLRUDetailTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory LRU Active / Inactive Detail"
			description: "Breakdown of memory pages in the kernel's active and inactive LRU lists, separated by anonymous (heap, tmpfs) and file-backed (caches, mmap) pages"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "bytes"
				}
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Inactive_file_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Inactive_file - File-backed memory on inactive LRU list"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Inactive_anon_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Inactive_anon - Anonymous memory on inactive LRU (incl. tmpfs & swap cache)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Active_file_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Active_file - File-backed memory on active LRU list"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Active_anon_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Active_anon - Anonymous memory on active LRU (incl. tmpfs & swap cache)"
					}
				}
			},
		]
	}
}

#memoryKernelCPUIOTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Kernel / CPU / IO"
			description: "Tracks kernel memory used for CPU-local structures, per-thread stacks, and bounce buffers used for I/O on DMA-limited devices. These areas are typically small but critical for low-level operations"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_KernelStack_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "KernelStack - Kernel stack memory (per-thread, non-reclaimable)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Percpu_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "PerCPU - Dynamically allocated per-CPU memory (used by kernel modules)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Bounce_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Bounce Memory - I/O buffer for DMA-limited devices"
					}
				}
			},
		]
	}
}

#memoryVmallocTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Vmalloc"
			description: "Usage of the kernel's vmalloc area, which provides virtual memory allocations for kernel modules and drivers. Includes total, used, and largest free block sizes"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "bytes"
				}
				querySettings: [{queryIndex: 1, colorMode: "fixed", colorValue: "#EA4747", lineStyle: "dashed", areaOpacity: 0}] // Vmalloc Total
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_VmallocChunk_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Vmalloc Free Chunk - Largest available block in vmalloc area"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_VmallocTotal_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Vmalloc Total - Total size of the vmalloc memory area"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_VmallocUsed_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Vmalloc Used - Portion of vmalloc area currently in use"
					}
				}
			},
		]
	}
}

#memoryAnonymousTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Anonymous"
			description: "Memory used by anonymous pages (not backed by files), including standard and huge page allocations. Includes heap, stack, and memory-mapped anonymous regions"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_AnonHugePages_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "AnonHugePages - Anonymous memory using HugePages"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_AnonPages_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "AnonPages - Anonymous memory (non-file-backed)"
					}
				}
			},
		]
	}
}

#memoryUnevictableMLockedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Unevictable and MLocked"
			description: "Memory that is locked in RAM and cannot be swapped out. Includes both kernel-unevictable memory and user-level memory locked with mlock()"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_Unevictable_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Unevictable - Kernel-pinned memory (not swappable)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_Mlocked_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "Mlocked - Application-locked memory via mlock()"
					}
				}
			},
		]
	}
}

#memoryDirectMapTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory DirectMap"
			description: "How much memory is directly mapped in the kernel using different page sizes (4K, 2M, 1G). Helps monitor large page utilization in the direct map region"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"node_memory_DirectMap1G_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "DirectMap 1G - Memory mapped with 1GB pages"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_DirectMap2M_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "DirectMap 2M - Memory mapped with 2MB pages"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_DirectMap4k_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "DirectMap 4K - Memory mapped with 4KB pages"
					}
				}
			},
		]
	}
}

#memoryHugePagesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory HugePages"
			description: "Displays HugePages memory usage in bytes, including allocated, free, reserved, and surplus memory. All values are calculated based on the number of huge pages multiplied by their configured size"
		}
		plugin: #detailedTimeSeriesChart & {
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
						query:            #"(node_memory_HugePages_Total{instance="$instance",job="$job"} - node_memory_HugePages_Free{instance="$instance",job="$job"}) * node_memory_Hugepagesize_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "HugePages Used - Currently allocated"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_HugePages_Rsvd{instance="$instance",job="$job"} * node_memory_Hugepagesize_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "HugePages Reserved - Promised but unused"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_HugePages_Surp{instance="$instance",job="$job"} * node_memory_Hugepagesize_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "HugePages Surplus - Dynamic pool extension"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_memory_HugePages_Total{instance="$instance",job="$job"} * node_memory_Hugepagesize_bytes{instance="$instance",job="$job"}"#
						seriesNameFormat: "HugePages Total - Reserved memory"
					}
				}
			},
		]
	}
}

#memoryPagesInOutPanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Pages In / Out"
			description: "Rate of memory pages being read from or written to disk (page-in and page-out operations). High page-out may indicate memory pressure or swapping activity"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
					show:  true
					label: "out (-) / in (+)"
				}
				querySettings: [{queryIndex: 1, negativeY: true}] // Pagesout
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pgpgin{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pagesin - Page in ops"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pgpgout{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pagesout - Page out ops"
					}
				}
			},
		]
	}
}

#memoryPagesSwapInOutPanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Pages Swap In / Out"
			description: "Rate at which memory pages are being swapped in from or out to disk. High swap-out activity may indicate memory pressure"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
					show:  true
					label: "out (-) / in (+)"
				}
				querySettings: [{queryIndex: 1, negativeY: true}] // Pagesout
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pswpin{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pswpin - Pages swapped in"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pswpout{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pswpout - Pages swapped out"
					}
				}
			},
		]
	}
}

#memoryPageFaultsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory Page Faults"
			description: "Rate of memory page faults, split into total, major (disk-backed), and derived minor (non-disk) faults. High major fault rates may indicate memory pressure or insufficient RAM"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pgfault{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pgfault - Page major and minor fault ops"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pgmajfault{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pgmajfault - Major page fault ops"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_pgfault{instance="$instance",job="$job"}[$__rate_interval])  - rate(node_vmstat_pgmajfault{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Pgminfault - Minor page fault ops"
					}
				}
			},
		]
	}
}

#memoryOOMKillerTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "OOM Killer"
			description: "Rate of Out-of-Memory (OOM) kill events. A non-zero value indicates the kernel has terminated one or more processes due to memory exhaustion"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
				querySettings: [{queryIndex: 0, colorMode: "fixed", colorValue: "#EA4747"}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_vmstat_oom_kill{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "OOM Kills"
					}
				}
			},
		]
	}
}

#timeSyncDriftTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Time Synchronized Drift"
			description: "Tracks the system clock's estimated and maximum error, as well as its offset from the reference clock (e.g., via NTP). Useful for detecting synchronization drift"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "seconds"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_estimated_error_seconds{instance="$instance",job="$job"}"#
						seriesNameFormat: "Estimated error"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_offset_seconds{instance="$instance",job="$job"}"#
						seriesNameFormat: "Offset local vs reference"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_maxerror_seconds{instance="$instance",job="$job"}"#
						seriesNameFormat: "Maximum error"
					}
				}
			},
		]
	}
}

#timePLLAdjustTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Time PLL Adjust"
			description: "NTP phase-locked loop (PLL) time constant used by the kernel to control time adjustments. Lower values mean faster correction but less stability"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_loop_time_constant{instance="$instance",job="$job"}"#
						seriesNameFormat: "PLL Time Constant"
					}
				}
			},
		]
	}
}

#timeSyncStatusTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Time Synchronized Status"
			description: "Shows whether the system clock is synchronized to a reliable time source, and the current frequency correction ratio applied by the kernel to maintain synchronization"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_sync_status{instance="$instance",job="$job"}"#
						seriesNameFormat: "Sync status (1 = ok)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_frequency_adjustment_ratio{instance="$instance",job="$job"}"#
						seriesNameFormat: "Frequency Adjustment"
					}
				}
			},
		]
	}
}

// It looks like timeseries charts doesn't have a unit for Hz
#timePPSFrequencyStabilityTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "PPS Frequency / Stability"
			description: "Displays the PPS signal's frequency offset and stability (jitter) in hertz. Useful for monitoring high-precision time sources like GPS or atomic clocks"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
					show:  true
					label: "Hz"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_pps_frequency_hertz{instance="$instance",job="$job"}"#
						seriesNameFormat: "PPS Frequency Offset"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_pps_stability_hertz{instance="$instance",job="$job"}"#
						seriesNameFormat: "PPS Frequency Stability"
					}
				}
			},
		]
	}
}

#timePPSAccuracyTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "PPS Time Accuracy"
			description: "Tracks PPS signal timing jitter and shift compared to system clock"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "seconds"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_pps_jitter_seconds{instance="$instance",job="$job"}"#
						seriesNameFormat: "PPS Jitter"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_timex_pps_shift_seconds{instance="$instance",job="$job"}"#
						seriesNameFormat: "PPS Shift"
					}
				}
			},
		]
	}
}

#timePPSSyncEventsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "PPS Sync Events"
			description: "Rate of PPS synchronization diagnostics including calibration events, jitter violations, errors, and frequency stability exceedances"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_timex_pps_calibration_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "PPS Calibrations/sec"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_timex_pps_error_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "PPS Errors/sec"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_timex_pps_stability_exceeded_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "PPS Stability Exceeded/sec"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_timex_pps_jitter_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "PPS Jitter Events/sec"
					}
				}
			},
		]
	}
}

#processesStatusTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Processes Status"
			description: "Processes currently in runnable or blocked states. Helps identify CPU contention or I/O wait bottlenecks"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_procs_blocked{instance="$instance",job="$job"}"#
						seriesNameFormat: "Blocked (I/O Wait)"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_procs_running{instance="$instance",job="$job"}"#
						seriesNameFormat: "Runnable (Ready for CPU)"
					}
				}
			},
		]
	}
}

// I don't have --collector.processes enabled so I'm unable to verify how this looks
#processesDetailedStatesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Processes Detailed States"
			description: "Current number of processes in each state (e.g., running, sleeping, zombie). Requires --collector.processes to be enabled in node_exporter"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_processes_state{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ state }}"
					}
				}
			},
		]
	}
}

#processesForksTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Processes Forks"
			description: "Rate of new processes being created on the system (forks/sec)"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_forks_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Process Forks per second"
					}
				}
			},
		]
	}
}

#processesCPUSaturationPerCoreTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "CPU Saturation per Core"
			description: "Shows CPU saturation per core, calculated as the proportion of time spent waiting to run relative to total time demanded (running + waiting)"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent-decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"((rate(node_schedstat_running_seconds_total{instance="$instance",job="$job"}[$__rate_interval]) + rate(node_schedstat_waiting_seconds_total{instance="$instance",job="$job"}[$__rate_interval])) > bool 0) * (rate(node_schedstat_waiting_seconds_total{instance="$instance",job="$job"}[$__rate_interval]) / (rate(node_schedstat_running_seconds_total{instance="$instance",job="$job"}[$__rate_interval]) + rate(node_schedstat_waiting_seconds_total{instance="$instance",job="$job"}[$__rate_interval])))"#
						seriesNameFormat: "CPU {{cpu}}"
					}
				}
			},
		]
	}
}

// I don't have --collector.processes enabled so I'm unable to verify how this looks
#processesPIDsNumberLimitTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "PIDs Number and Limit"
			description: "Number of active PIDs on the system and the configured maximum allowed. Useful for detecting PID exhaustion risk. Requires --collector.processes in node_exporter"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_processes_pids{instance="$instance",job="$job"}"#
						seriesNameFormat: "Number of PIDs"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_processes_max_processes{instance="$instance",job="$job"}"#
						seriesNameFormat: "PIDs limit"
					}
				}
			},
		]
	}
}

// I don't have --collector.processes enabled so I'm unable to verify how this looks
#processesThreadsNumberLimitTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Threads Number and Limit"
			description: "Number of active threads on the system and the configured thread limit. Useful for monitoring thread pressure. Requires --collector.processes in node_exporter"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_processes_threads{instance="$instance",job="$job"}"#
						seriesNameFormat: "Allocated threads"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_processes_max_threads{instance="$instance",job="$job"}"#
						seriesNameFormat: "Threads limit"
					}
				}
			},
		]
	}
}

#contextSwitchesInterruptsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Context Switches / Interrupts"
			description: "Per-second rate of context switches and hardware interrupts. High values may indicate intense CPU or I/O activity"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_context_switches_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Context switches"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_intr_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "Interrupts"
					}
				}
			},
		]
	}
}

#systemLoadTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "System Load"
			description: "System load average over 1, 5, and 15 minutes. Reflects the number of active or waiting processes. Values above CPU core count may indicate overload"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
				querySettings: [{queryIndex: 3, areaOpacity: 0, lineStyle: "dashed", colorMode: "fixed", colorValue: "#EA4747"}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_load1{instance="$instance",job="$job"}"#
						seriesNameFormat: "Load 1m"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_load5{instance="$instance",job="$job"}"#
						seriesNameFormat: "Load 5m"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_load15{instance="$instance",job="$job"}"#
						seriesNameFormat: "Load 15m"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"count(count(node_cpu_seconds_total{instance="$instance",job="$job"}) by (cpu))"#
						seriesNameFormat: "CPU Core Count"
					}
				}
			},
		]
	}
}

// It looks like timeseries charts doesn't have a unit for Hz
#CPUFrequencyScalingTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "CPU Frequency Scaling"
			description: "Real-time CPU frequency scaling per core, including average minimum and maximum allowed scaling frequencies"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
					show:  true
					label: "Hz"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_cpu_scaling_frequency_hertz{instance="$instance",job="$job"}"#
						seriesNameFormat: "CPU {{ cpu }}"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(node_cpu_scaling_frequency_max_hertz{instance="$node",job="$job"})"#
						seriesNameFormat: "Max"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"avg(node_cpu_scaling_frequency_min_hertz{instance="$instance",job="$job"})"#
						seriesNameFormat: "Min"
					}
				}
			},
		]
	}
}

#CPUScheduleTimeslicesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "CPU Schedule Timeslices"
			description: "Rate of scheduling timeslices executed per CPU. Reflects how frequently the scheduler switches tasks on each core"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_schedstat_timeslices_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "CPU {{ cpu }}"
					}
				}
			},
		]
	}
}

// I don't have --collector.interrupts enabled so I'm unable to verify how this looks
#IRQDetailTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "IRQ Detail"
			description: "Breaks down hardware interrupts by type and device. Useful for diagnosing IRQ load on network, disk, or CPU interfaces. Requires --collector.interrupts to be enabled in node_exporter"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_interrupts_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ type }} - {{ info }}"
					}
				}
			},
		]
	}
}

#entropyTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Entropy"
			description: "Number of bits of entropy currently available to the system's random number generators (e.g., /dev/random). Low values may indicate that random number generation could block or degrade performance of cryptographic operations"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decbits"
				}
				querySettings: [{queryIndex: 1, areaOpacity: 0, lineStyle: "dashed", colorMode: "fixed", colorValue: "#EA4747"}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_entropy_available_bits{instance="$instance",job="$job"}"#
						seriesNameFormat: "Entropy available"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_entropy_pool_size_bits{instance="$instance",job="$job"}"#
						seriesNameFormat: "Entropy pool max"
					}
				}
			},
		]
	}
}

#hardwareTemperatureTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Hardware Temperature Monitor"
			description: "Monitors hardware sensor temperatures and critical thresholds as exposed by Linux hwmon. Includes CPU, GPU, and motherboard sensors where available"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "celsius"
				}
				querySettings: [{queryIndex: 1, areaOpacity: 0, lineStyle: "dashed", colorMode: "fixed", colorValue: "#EA4747"}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_hwmon_temp_celsius{instance="$instance",job="$job"} * on(chip) group_left(chip_name) node_hwmon_chip_names{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ chip_name }} {{ sensor }}"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_hwmon_temp_crit_celsius{instance="$instance",job="$job"} * on(chip) group_left(chip_name) node_hwmon_chip_names{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ chip_name }} {{ sensor }} Critical"
					}
				}
			},
		]
	}
}

#coolingDeviceUtilizationTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Cooling Device Utilization"
			description: "Shows how hard each cooling device (fan/throttle) is working relative to its maximum capacity"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(node_cooling_device_max_state{instance="$instance",job="$job"} > bool 0) * (100 * node_cooling_device_cur_state{instance="$instance",job="$job"} / node_cooling_device_max_state{instance="$instance",job="$job"})"#
						seriesNameFormat: "{{name}} - {{type}}"
					}
				}
			},
		]
	}
}

// I have no data for this query so unable to verify how the panel looks.
#powerSupplyTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Power Supply"
			description: "Shows the online status of power supplies (e.g., AC, battery). A value of 1-Yes indicates the power supply is active/online"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_power_supply_online{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ power_supply }} online"
					}
				}
			},
		]
	}
}

// I have no data for this query so unable to verify how the panel looks.
// Timeseries charts in Perses doesn't have a unit for RPM (Revolutions per minute).
#hardwareFanSpeedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Hardware Fan Speed"
			description: "Displays the current fan speeds (RPM) from hardware sensors via the hwmon interface"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
					show:  true
					label: "rpm"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_hwmon_fan_rpm{instance="$instance",job="$job"} * on(chip) group_left(chip_name) node_hwmon_chip_names{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ chip_name }} {{ sensor }}"
					}
				}
			},
		]
	}
}

#systemdUnitsStateTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Systemd Units State"
			description: "Current number of systemd units in each operational state, such as active, failed, inactive, or transitioning"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
				querySettings: [{queryIndex: 3, colorMode: "fixed", colorValue: "#EA4747"}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_systemd_units{instance="$instance",job="$job",state="activating"}"#
						seriesNameFormat: "Activating"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_systemd_units{instance="$instance",job="$job",state="active"}"#
						seriesNameFormat: "Active"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_systemd_units{instance="$instance",job="$job",state="deactivating"}"#
						seriesNameFormat: "Deactivating"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_systemd_units{instance="$instance",job="$job",state="failed"}"#
						seriesNameFormat: "Failed"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_systemd_units{instance="$instance",job="$job",state="inactive"}"#
						seriesNameFormat: "Inactive"
					}
				}
			},
		]
	}
}

#systemdSocketsCurrentTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Systemd Sockets Current"
			description: "Current number of active connections per systemd socket, as reported by the Node Exporter systemd collector"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_systemd_socket_current_connections{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ name }}"
					}
				}
			},
		]
	}
}

#systemdSocketsAcceptedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Systemd Sockets Accepted"
			description: "Rate of accepted connections per second for each systemd socket"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "events/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_systemd_socket_accepted_connections_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ name }}"
					}
				}
			},
		]
	}
}

#systemdSocketsRefusedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Systemd Sockets Refused"
			description: "Rate of systemd socket connection refusals per second, typically due to service unavailability or backlog overflow"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "events/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_systemd_socket_refused_connections_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ name }}"
					}
				}
			},
		]
	}
}

#diskReadWriteIOpsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Read/Write IOps"
			description: "Number of I/O operations completed per second for the device (after merges), including both reads and writes"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
					show:  true
					label: "read (-) / write (+)"
				}
				querySettings: [{queryIndex: 0, negativeY: true}] // Read
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_reads_completed_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_writes_completed_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Write"
					}
				}
			},
		]
	}
}

#diskReadWriteDataTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Read/Write Data"
			description: "Number of bytes read from or written to the device per second"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decbytes/sec"
					show:  true
					label: "read (-) / write (+)"
				}
				querySettings: [{queryIndex: 0, negativeY: true}] // Read
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_read_bytes_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_written_bytes_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Write"
					}
				}
			},
		]
	}
}

#diskAverageWaitTimeTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Average Wait Time"
			description: "Average time for requests issued to the device to be served. This includes the time spent by the requests in queue and the time spent servicing them"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "seconds"
					show:  true
					label: "read (-) / write (+)"
				}
				querySettings: [{queryIndex: 0, negativeY: true}] // Read
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(rate(node_disk_reads_completed_total{instance="$instance",job="$job"}[$__rate_interval]) > bool 0) * (rate(node_disk_read_time_seconds_total{instance="$instance",job="$job"}[$__rate_interval]) / rate(node_disk_reads_completed_total{instance="$instance",job="$job"}[$__rate_interval]))"#
						seriesNameFormat: "{{ device }} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"(rate(node_disk_writes_completed_total{instance="$instance",job="$job"}[$__rate_interval]) > bool 0) * (rate(node_disk_write_time_seconds_total{instance="$instance",job="$job"}[$__rate_interval]) / rate(node_disk_writes_completed_total{instance="$instance",job="$job"}[$__rate_interval]))"#
						seriesNameFormat: "{{ device }} - Write"
					}
				}
			},
		]
	}
}

#diskAverageQueueSizeTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Average Queue Size"
			description: "Average queue length of the requests that were issued to the device"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_io_time_weighted_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }}"
					}
				}
			},
		]
	}
}

#diskReadWriteMergedTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk R/W Merged"
			description: "Number of read and write requests merged per second that were queued to the device"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
					show:  true
					label: "read (-) / write (+)"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_reads_merged_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_writes_merged_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Write"
					}
				}
			},
		]
	}
}

#diskTimeIOsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Time Spent Doing I/Os"
			description: "Percentage of time the disk spent actively processing I/O operations, including general I/O, discards (TRIM), and write cache flushes"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "percent-decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_io_time_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - General IO"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_discard_time_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Discard/TRIM"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_flush_requests_time_seconds_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Flush (write cache)"
					}
				}
			},
		]
	}
}

#diskOpsDiscardsFlushTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Ops Discards / Flush"
			description: "Per-second rate of discard (TRIM) and flush (write cache) operations. Useful for monitoring low-level disk activity on SSDs and advanced storage"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "ops/sec"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_discards_completed_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Discards completed"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_discards_merged_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Discards merged"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_flush_requests_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }} - Flush"
					}
				}
			},
		]
	}
}

#diskSectorsDiscardedSuccessTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Disk Sectors Discarded Successfully"
			description: "Shows how many disk sectors are discarded (TRIMed) per second. Useful for monitoring SSD behavior and storage efficiency"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(node_disk_discarded_sectors_total{instance="$instance",job="$job"}[$__rate_interval])"#
						seriesNameFormat: "{{ device }}"
					}
				}
			},
		]
	}
}

#diskInstantaneousQueueSizeTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Instantaneous Queue Size"
			description: "Number of in-progress I/O requests at the time of sampling (active requests in the disk queue)"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_disk_io_now{instance="$instance",job="$job"}"#
						seriesNameFormat: "{{ device }}"
					}
				}
			},
		]
	}
}

#fileDescriptorTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "File Descriptor"
			description: "Number of file descriptors currently allocated system-wide versus the system limit. Important for detecting descriptor exhaustion risks"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
				querySettings: [{queryIndex: 0, areaOpacity: 0, colorMode: "fixed", lineStyle: "dashed", colorValue: "#EA4747"}] // Max open files
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_filefd_maximum{instance="$instance",job="$job"}"#
						seriesNameFormat: "Max open files"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_filefd_allocated{instance="$instance",job="$job"}"#
						seriesNameFormat: "Open files"
					}
				}
			},
		]
	}
}

#fileNodesFreeTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "File Nodes Free"
			description: "Number of free file nodes (inodes) available per mounted filesystem. A low count may prevent file creation even if disk space is available"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_filesystem_files_free{instance="$instance",job="$job",device!~'rootfs'}"#
						seriesNameFormat: "{{ mountpoint }}"
					}
				}
			},
		]
	}
}

// Perses does not have the type "Yes/No" from Grafana, so use 0/1 for now.
#filesystemInReadOnlyErrorTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Filesystem in ReadOnly / Error"
			description: "Indicates filesystems mounted in read-only mode or reporting device-level I/O errors"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_filesystem_readonly{instance="$instance",job="$job",device!~'rootfs'}"#
						seriesNameFormat: "{{ mountpoint }} - ReadOnly"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_filesystem_device_error{instance="$instance",job="$job",device!~'rootfs',fstype!~'tmpfs'}"#
						seriesNameFormat: "{{ mountpoint }} - Device error"
					}
				}
			},
		]
	}
}

#fileNodesSizeTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "File Nodes Size"
			description: "Number of file nodes (inodes) available per mounted filesystem. Reflects maximum file capacity regardless of disk size"
		}
		plugin: #detailedTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"node_filesystem_files{instance="$instance",job="$job",device!~'rootfs'}"#
						seriesNameFormat: "{{ mountpoint }}"
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
					#diskIOpsTimePanel,
					#diskThroughputTimePanel,
					#filesystemSpaceTimePanel,
					#filesystemUsedTimePanel,
					#diskIOUtilizationTimePanel,
					#pressureStallInfoTimePanel,
				]
			},
			{
				#title:       "Memory Meminfo"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#memoryCommitedTimePanel,
					#memoryWritebackDirtyTimePanel,
					#memorySlabTimePanel,
					#memorySharedMappedTimePanel,
					#memoryLRUTimePanel,
					#memoryLRUDetailTimePanel,
					#memoryKernelCPUIOTimePanel,
					#memoryVmallocTimePanel,
					#memoryAnonymousTimePanel,
					#memoryUnevictableMLockedTimePanel,
					#memoryDirectMapTimePanel,
					#memoryHugePagesTimePanel,
				]
			},
			{
				#title:       "Memory Vmstat"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#memoryPagesInOutPanel,
					#memoryPagesSwapInOutPanel,
					#memoryPageFaultsTimePanel,
					#memoryOOMKillerTimePanel,
				]
			},
			{
				#title:       "System Timesync"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#timeSyncDriftTimePanel,
					#timePLLAdjustTimePanel,
					#timeSyncStatusTimePanel,
					#timePPSFrequencyStabilityTimePanel,
					#timePPSAccuracyTimePanel,
					#timePPSSyncEventsTimePanel,
				]
			},
			{
				#title:       "System Processes"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#processesStatusTimePanel,
					#processesDetailedStatesTimePanel,
					#processesForksTimePanel,
					#processesCPUSaturationPerCoreTimePanel,
					#processesPIDsNumberLimitTimePanel,
					#processesThreadsNumberLimitTimePanel,
				]
			},
			{
				#title:       "System Misc"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#contextSwitchesInterruptsTimePanel,
					#systemLoadTimePanel,
					#CPUFrequencyScalingTimePanel,
					#CPUScheduleTimeslicesTimePanel,
					#IRQDetailTimePanel,
					#entropyTimePanel,
				]
			},
			{
				#title:       "Hardware Misc"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#hardwareTemperatureTimePanel,
					#coolingDeviceUtilizationTimePanel,
					#powerSupplyTimePanel,
					#hardwareFanSpeedTimePanel,
				]
			},
			{
				#title:       "Systemd"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#systemdUnitsStateTimePanel,
					#systemdSocketsCurrentTimePanel,
					#systemdSocketsAcceptedTimePanel,
					#systemdSocketsRefusedTimePanel,
				]
			},
			{
				#title:       "Storage disk"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#diskReadWriteIOpsTimePanel,
					#diskReadWriteDataTimePanel,
					#diskAverageWaitTimeTimePanel,
					#diskAverageQueueSizeTimePanel,
					#diskReadWriteMergedTimePanel,
					#diskTimeIOsTimePanel,
					#diskOpsDiscardsFlushTimePanel,
					#diskSectorsDiscardedSuccessTimePanel,
					#diskInstantaneousQueueSizeTimePanel,
				]
			},
			{
				#title:       "Storage Filesystem"
				#cols:        2
				#height:      8
				#isCollapsed: true
				#panels: [
					#fileDescriptorTimePanel,
					#fileNodesFreeTimePanel,
					#filesystemInReadOnlyErrorTimePanel,
					#fileNodesSizeTimePanel,
				]
			},
		]
	}
}
