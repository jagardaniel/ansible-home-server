// Perses dashboard for Prometheus podman exporter
//
// Prometheus exporter used: https://github.com/containers/prometheus-podman-exporter
// Layout idea: https://grafana.com/grafana/dashboards/15798-docker-monitoring/ / https://grafana.com/grafana/dashboards/193-docker-monitoring/

// I had to override the "user@.service" unit and append "io" to the Delegate= row to be able to see block statistics for each container.

package mydac

import (
	dashboardBuilder "github.com/perses/perses/cue/dac-utils/dashboard"
	labelValuesVarBuilder "github.com/perses/plugins/prometheus/sdk/cue/variable/labelvalues"
	timeseriesChart "github.com/perses/plugins/timeserieschart/schemas:model"
	statChart "github.com/perses/plugins/statchart/schemas:model"
	panelBuilder "github.com/perses/plugins/prometheus/sdk/cue/panel"
	panelGroupsBuilder "github.com/perses/perses/cue/dac-utils/panelgroups"
	promQuery "github.com/perses/plugins/prometheus/schemas/prometheus-time-series-query:model"
)

#baseStatChart: statChart & {
	spec: {
		colorMode: "none"
	}
}

#baseTimeSeriesChart: timeseriesChart & {
	spec: {
		visual: {
			areaOpacity: 0.4
			display:     "line"
			lineStyle:   "solid"
			lineWidth:   1.25
			pointRadius: 2.75
		}

		legend: {
			mode:     "table"
			position: "right"
			values: [
				"mean",
				"max",
				"last",
			]
			"size": "medium"
		}
	}
}

#runningContainersStatPanel: panelBuilder & {
	spec: {
		display: name: "Running containers"
		plugin: #baseStatChart

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"count(podman_container_state{instance=~"$instance"} == 2)"#
					}
				}
			},
		]
	}
}

#totalMemoryUsageStatPanel: panelBuilder & {
	spec: {
		display: name: "Total Memory Usage"
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
						query: #"sum(podman_container_mem_usage_bytes{instance=~"$instance"})"#
					}
				}
			},
		]
	}
}

#totalCPUUsageStatPanel: panelBuilder & {
	spec: {
		display: name: "Total CPU Usage"
		plugin: #baseStatChart & {
			spec: {
				format: {
					unit: "percent"
				}
			}
		}

		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query: #"sum(rate(podman_container_cpu_seconds_total{instance=~"$instance"}[$__rate_interval])) * 100"#
					}
				}
			},
		]
	}
}

#CPUUsageTimePanel: panelBuilder & {
	spec: {
		display: name: "CPU Usage"
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
						query:            #"(rate(podman_container_cpu_seconds_total[$__rate_interval]) * 100) * on (id, instance, job) group_left (name) podman_container_info{instance=~"$instance"}"#
						seriesNameFormat: "{{ name }}"
					}
				}
			},
		]
	}
}

#memoryUsageTimePanel: panelBuilder & {
	spec: {
		display: name: "Memory Usage"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "bytes"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"podman_container_mem_usage_bytes * on (id, instance, job) group_left (name) podman_container_info{instance=~"$instance"}"#
						seriesNameFormat: "{{ name }}"
					}
				}
			},
		]
	}
}

#networkUsageTimePanel: panelBuilder & {
	spec: {
		display: name: "Network Usage"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "decbytes/sec"
				querySettings: [{queryIndex: 1, negativeY: true}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(podman_container_net_input_total[$__rate_interval]) * on (id, instance, job) group_left (name) podman_container_info{instance=~"$instance"}"#
						seriesNameFormat: "{{ name }} - Rx in"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(podman_container_net_output_total[$__rate_interval]) * on (id, instance, job) group_left (name) podman_container_info{instance=~"$instance"}"#
						seriesNameFormat: "{{ name }} - Tx out"
					}
				}
			},
		]
	}
}

#diskUsageTimePanel: panelBuilder & {
	spec: {
		display: name: "Disk Throughput"
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "decbytes/sec"
				querySettings: [{queryIndex: 0, negativeY: true}]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(podman_container_block_input_total[$__rate_interval]) * on (id, instance, job) group_left (name) podman_container_info{instance=~"$instance"}"#
						seriesNameFormat: "{{ name }} - Read"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"rate(podman_container_block_output_total[$__rate_interval]) * on (id, instance, job) group_left (name) podman_container_info{instance=~"$instance"}"#
						seriesNameFormat: "{{ name }} - Write"
					}
				}
			},
		]
	}
}

#instanceVar: labelValuesVarBuilder & {
	#name:          "instance"
	#query:         "podman_container_info"
	#label:         "instance"
	#allowAllValue: true
	#allowMultiple: true
}

// Can be added if we want a variable to filter based on container name(s).
// Add #containerVar to dashboardBuilder #variables and then modify the queries.
// Example: podman_container_info{instance=~"$instance", name=~"$container"}
//
// #containerVar: labelValuesVarBuilder & {
// 	#name:          "container"
// 	#label:         "name"
// 	#metric:        "podman_container_info"
// 	#matchers:      [#"podman_container_info{instance=~"$instance"}"#]
// 	#allowAllValue: true
// 	#allowMultiple: true
// }

dashboardBuilder & {
	#name:    "podman"
	#project: "home"
	#display: name: "Podman"
	#duration:        "6h"
	#refreshInterval: "1m"
	#variables:       [#instanceVar.variable]

	#panelGroups: panelGroupsBuilder & {
		#input: [
			{
				#title:  "Overview"
				#cols:   3
				#height: 5
				#panels: [
					#runningContainersStatPanel,
					#totalMemoryUsageStatPanel,
					#totalCPUUsageStatPanel,
				]
			},
			{
				#title:  "Basic CPU / Memory / Network / Disk"
				#cols:   1
				#height: 8
				#panels: [
					#CPUUsageTimePanel,
					#memoryUsageTimePanel,
					#networkUsageTimePanel,
					#diskUsageTimePanel,
				]
			},
		]
	}
}
