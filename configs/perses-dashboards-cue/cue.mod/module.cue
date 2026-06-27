module: "cue.example"
language: {
	version: "v0.16.1"
}
deps: {
	"github.com/perses/perses/cue@v0": {
		v: "v0.53.1"
	}
	"github.com/perses/plugins/prometheus@v0": {
		v:       "v0.57.1"
		default: true
	}
	"github.com/perses/plugins/statchart@v0": {
		v:       "v0.12.1"
		default: true
	}
	"github.com/perses/plugins/timeserieschart@v0": {
		v:       "v0.12.1"
		default: true
	}
	"github.com/perses/shared/cue@v0": {
		v:       "v0.53.1"
		default: true
	}
}
