// This is an attempt to copy each panel from Grafana's Unbound exporter dashboard to Perses, with CUE.
// Layout, queries, panels, text and description are made by the person or people behind the Unbound exporter dashboard:
// https://grafana.com/grafana/dashboards/21006-unbound/
// https://github.com/rfmoz/grafana-dashboards

// Prometheus exporter used: https://github.com/letsencrypt/unbound_exporter

package mydac

import (
	dashboardBuilder "github.com/perses/perses/cue/dac-utils/dashboard"
	labelValuesVarBuilder "github.com/perses/plugins/prometheus/sdk/cue/variable/labelvalues"
	panelBuilder "github.com/perses/plugins/prometheus/sdk/cue/panel"
	promQuery "github.com/perses/plugins/prometheus/schemas/prometheus-time-series-query:model"
	panelGroupsBuilder "github.com/perses/perses/cue/dac-utils/panelgroups"
	timeseriesChart "github.com/perses/plugins/timeserieschart/schemas:model"
)

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
		visual: {
			areaOpacity: 0.4
			display:     "line"
			lineStyle:   "solid"
			lineWidth:   1.25
			pointRadius: 2.75
		}
	}
}

#queryTypesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by type"
			description: "Number of queries with a given query type."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_types_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "{{type}}"
					}
				}
			},
		]
	}
}

#answerRcodesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Answers by response code"
			description: "Number of answers to queries, from cache or from recursion, by response code."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_answer_rcodes_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "{{rcode}}"
					}
				}
			},
		]
	}
}

#cacheHitsMissesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Cache hits / misses - stacked"
			description: "Number of queries that were successfully answered using a cache lookup. Number of cache queries that needed recursive processing."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "ops/sec"
				visual: stack: "all"
				querySettings: [
					{colorMode: "fixed", colorValue: "#EA4747", queryIndex: 0},
					{colorMode: "fixed", colorValue: "#2FBF71", queryIndex: 1},
				]
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(irate(unbound_cache_misses_total{instance="$instance"}[$__rate_interval]))"#
						seriesNameFormat: "misses"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(irate(unbound_cache_hits_total{instance="$instance"}[$__rate_interval]))"#
						seriesNameFormat: "hits"
					}
				}
			},
		]
	}
}

#queryTotalTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Total queries by thread - stacked"
			description: "Number of queries handled by each worker thread."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_queries_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "thread {{thread}}"
					}
				}
			},
		]
	}
}

// Response time panel from Grafana is a heatmap and not supported yet - ignore
// [----------]

#memoryCachesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory used by caches"
			description: "Memory in use by caches, in bytes."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "bytes"
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_memory_caches_bytes{instance="$instance"}"#
						seriesNameFormat: "{{cache}}"
					}
				}
			},
		]
	}
}

#queryFlagsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by flag"
			description: "Number of queries that had a given flag set in the header."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "requests/sec"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_flags_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "{{flag}}"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_edns_present_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "EDNS OPT"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_edns_DO_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "DO (DNSSEC OK)"
					}
				}
			},
		]
	}
}

#queryProtocolsTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by protocol in / out"
			description: "Number of queries that the Unbound server made using TCP outgoing towards other servers. Number of queries that the Unbound server made using UDP outgoing towards other servers. Number of queries that were made using TCP towards the Unbound server, including DoT and DoH queries."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "requests/sec"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_tcpout_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "TCP out"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_udpout_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "UDP out"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_tcp_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "TCP in"
					}
				}
			},
		]
	}
}

#queryClassTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by class"
			description: "Number of queries with a given query class."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_classes_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "{{class}}"
					}
				}
			},
		]
	}
}

#queryOpcodeTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by opcode"
			description: "Number of queries with a given query opcode."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_opcodes_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "{{opcode}}"
					}
				}
			},
		]
	}
}

#queryMethodTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by method"
			description: "Number of DoH queries that were made towards the Unbound server. Number of queries that were made using TCP TLS towards the Unbound server, including DoT and DoH queries. Number of queries that were made using TCP TLS Resume towards the Unbound server."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "requests/sec"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_https_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "HTTPS"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_tls_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "TLS"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_tls_resume_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "TLS Resume"
					}
				}
			},
		]
	}
}

#queryIPv6TimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries by IPv6"
			description: "Number of queries that were made using IPv6 towards the Unbound server."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "requests/sec"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_ipv6_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "IPv6"
					}
				}
			},
		]
	}
}

#answersBogusTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Answers bogus"
			description: "Number of rrsets marked bogus by the validator. Number of answers that were bogus."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_answers_bogus{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "Bogus"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_rrset_bogus_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "RRset bogus"
					}
				}
			},
		]
	}
}

#answersSecureTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Answers secure"
			description: "Number of answers that were secure."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_answers_secure_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "Secure"
					}
				}
			},
		]
	}
}

#cacheCountTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Cached messages / rrset"
			description: "Number of Messages cached. Number of rrset cached."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "decimal"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_msg_cache_count{instance="$instance"}"#
						seriesNameFormat: "messages"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_rrset_cache_count{instance="$instance"}"#
						seriesNameFormat: "rrset"
					}
				}
			},
		]
	}
}

#cachePrefetchesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Cache prefetches - stacked"
			description: "Number of cache prefetches performed."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_prefetches_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "thread {{thread}}"
					}
				}
			},
		]
	}
}

#requestListTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Request list size"
			description: "Current size of the request list."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(unbound_request_list_current_all{instance="$instance"})"#
						seriesNameFormat: "including internally generated queries"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(unbound_request_list_current_user{instance="$instance"})"#
						seriesNameFormat: "only counting the requests from client queries"
					}
				}
			},
		]
	}
}

#requestListIssuesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Request list issues"
			description: "Unexpected events over request list."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "decimal"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(irate(unbound_request_list_overwritten_total{instance="$instance"}[$__rate_interval]))"#
						seriesNameFormat: "requests in the request list that were overwritten by newer entries"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"sum(irate(unbound_request_list_exceeded_total{instance="$instance"}[$__rate_interval]))"#
						seriesNameFormat: "queries that were dropped because the request list was full"
					}
				}
			},
		]
	}
}

#memoryModulesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory used by modules"
			description: "Memory in use by modules."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "bytes"
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_memory_modules_bytes{instance="$instance"}"#
						seriesNameFormat: "{{module}}"
					}
				}
			},
		]
	}
}

#memoryDoHTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Memory used by DoH buffers"
			description: "Memory used by DoH buffers, in bytes."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "bytes"
				visual: stack: "all"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_memory_doh_bytes{buffer="query_buffer",instance="$instance"}"#
						seriesNameFormat: "query buffer"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_memory_doh_bytes{buffer="response_buffer",instance="$instance"}"#
						seriesNameFormat: "response buffer"
					}
				}
			},
		]
	}
}

// This panel has stacked in the name but doesn't seem to be configured as stacked in Grafana.
#expiredEntriesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Expired entries - stacked"
			description: "Number of expired entries served."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "requests/sec"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_expired_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "thread {{thread}}"
					}
				}
			},
		]
	}
}

// Same here
#recursiveRepliesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Replies sent to recursive queries - stacked"
			description: "Number of replies sent to queries that needed recursive processing."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_recursive_replies_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "thread {{thread}}"
					}
				}
			},
		]
	}
}

#unwantedQueriesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Queries / Replies refused by access control"
			description: "Number of queries that were refused or dropped because they failed the access control settings. Number of replies that were unwanted or unsolicited."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_unwanted_queries_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "queries"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_unwanted_replies_total{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "replies"
					}
				}
			},
		]
	}
}

#recursionTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "Recursive processing time"
			description: "Average time it took to answer queries that needed recursive processing (does not include in-cache requests). The median of the time it took to answer queries that needed recursive processing."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: format: unit: "seconds"
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_recursion_time_seconds_avg{instance="$instance"}"#
						seriesNameFormat: "average"
					}
				}
			},
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"unbound_recursion_time_seconds_median{instance="$instance"}"#
						seriesNameFormat: "median"
					}
				}
			},
		]
	}
}

#NSECResponsesTimePanel: panelBuilder & {
	spec: {
		display: {
			name:        "NSEC responses"
			description: "Number of queries that the Unbound server generated response using Aggressive NSEC."
		}
		plugin: #baseTimeSeriesChart & {
			spec: {
				yAxis: {
					format: unit: "requests/sec"
					min: 0
				}
			}
		}
		queries: [
			{
				kind: "TimeSeriesQuery"
				spec: plugin: promQuery & {
					spec: {
						query:            #"irate(unbound_query_aggressive_nsec{instance="$instance"}[$__rate_interval])"#
						seriesNameFormat: "{{rcode}}"
					}
				}
			},
		]
	}
}

#instanceVar: labelValuesVarBuilder & {
	#name:  "instance"
	#query: "unbound_up"
	#label: "instance"
}

dashboardBuilder & {
	#name:    "unbound"
	#project: "home"
	#display: name: "Unbound"
	#duration:        "6h"
	#refreshInterval: "1m"
	#variables:       [#instanceVar.variable]

	#panelGroups: panelGroupsBuilder & {
		#input: [
			{
				#title:  "Principal"
				#cols:   2
				#height: 11
				#panels: [
					#queryTypesTimePanel,
					#answerRcodesTimePanel,
					#cacheHitsMissesTimePanel,
					#queryTotalTimePanel,
					#memoryCachesTimePanel,
				]
			},
			{
				#title:       "Queries details"
				#cols:        2
				#height:      12
				#isCollapsed: true
				#panels: [
					#queryFlagsTimePanel,
					#queryProtocolsTimePanel,
					#queryClassTimePanel,
					#queryOpcodeTimePanel,
					#queryMethodTimePanel,
					#queryIPv6TimePanel,
				]
			},
			{
				#title:       "Answer details"
				#cols:        2
				#height:      12
				#isCollapsed: true
				#panels: [
					#answersBogusTimePanel,
					#answersSecureTimePanel,
				]
			},
			{
				#title:       "Cache"
				#cols:        2
				#height:      12
				#isCollapsed: true
				#panels: [
					#cacheCountTimePanel,
					#cachePrefetchesTimePanel,
				]
			},
			{
				#title:       "Request list"
				#cols:        2
				#height:      12
				#isCollapsed: true
				#panels: [
					#requestListTimePanel,
					#requestListIssuesTimePanel,
				]
			},
			{
				#title:       "Memory"
				#cols:        2
				#height:      12
				#isCollapsed: true
				#panels: [
					#memoryModulesTimePanel,
					#memoryDoHTimePanel,
				]
			},
			{
				#title:       "Misc"
				#cols:        2
				#height:      12
				#isCollapsed: true
				#panels: [
					#expiredEntriesTimePanel,
					#recursiveRepliesTimePanel,
					#unwantedQueriesTimePanel,
					#recursionTimePanel,
					#NSECResponsesTimePanel,
				]
			},
		]
	}
}
