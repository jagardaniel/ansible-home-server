module: "github.com/jagardaniel/ansible-home-server/configs/perses/dashboards"
language: version: "v0.18.0"
deps: {
	"github.com/perses/perses/cue@v0": v: "v0.54.0"
	"github.com/perses/plugins/prometheus@v0": {
		v:       "v0.58.0"
		default: true
	}
	"github.com/perses/plugins/statchart@v0": {
		v:       "v0.13.0"
		default: true
	}
	"github.com/perses/plugins/timeserieschart@v0": {
		v:       "v0.13.0"
		default: true
	}
	"github.com/perses/shared/cue@v0": v: "v0.54.0"
	"github.com/perses/spec/cue@v0": v:   "v0.2.0"
}
