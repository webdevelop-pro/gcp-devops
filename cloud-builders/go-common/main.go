package main

import (
	"github.com/webdevelop-pro/go-common/configurator"
	"github.com/webdevelop-pro/go-common/server"
	"github.com/webdevelop-pro/go-common/verser"
	echoswagger "github.com/webdevelop-pro/go-echo-swagger"
	logger "github.com/webdevelop-pro/go-logger"
	"go.uber.org/fx"
)

var (
	service    string
	version    string
	repository string
	revisionID string
)

// @schemes https
func main() {
	verser.SetServiVersRepoRevis(service, version, repository, revisionID)
	fx.New(
		fx.Logger(logger.NewComponentLogger("fx", nil)),
		fx.Provide(
			// Configurator
			configurator.NewConfigurator,
			// Http Server
			server.New,
		),

		fx.Invoke(
			// Run HTTP server
			RunHttpServer,
		),
	).Run()
}

func RunHttpServer(lc fx.Lifecycle, srv *server.HttpServer, c *configurator.Configurator) {
	server.StartServer(lc, srv)
	echoswagger.New(c, srv.Echo)
}
